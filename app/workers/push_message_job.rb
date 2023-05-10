class PushMessageJob
  include Sidekiq::Worker

  def perform(id)
    puts "PushMessageJob at: #{Time.now.strftime('%d/%m/%Y %H:%M')}"
    puts "PushMessageJob id: #{id}"

    @push_message = PushMessage.find_by_id(id.to_i)
    return if Time.now <= @push_message.started_at || @push_message.subscribe_status_unsubscribe?

    @chatbot = @push_message.chatbot

    @scenario_user_responses = ScenarioUserResponse.where(scenario_id: @chatbot.scenario_selected)
                                                   .joins('left join scenario_user_response_selenium_results sursr'\
                                                   ' on sursr.user_input_id = scenario_user_responses.user_input_id'\
                                                   ' and sursr.scenario_id  = scenario_user_responses.scenario_id')
                                                   .joins('left join push_message_histories pmh '\
                                                   ' on pmh.user_input_id  = scenario_user_responses.user_input_id'\
                                                   ' and pmh.scenario_id = scenario_user_responses.scenario_id')
                                                   .where('sursr.id is null and pmh.id is null')
    return if @scenario_user_responses.length === 0

    last_message_time_user_responses = create_last_message_time_user_reponses

    last_message_time_user_responses.each do |user_input_id, value|
      next if value + @push_message.last_message_datetime_since * 60 > Time.now

      user_responses = @scenario_user_responses.select { |each| each.user_input_id == user_input_id }
      if @push_message.sending_method_sms?
        user_response = @scenario_user_responses.find do |each|
          each.data_input_name == 'phone' || each.data_input_name == 'phone_number'
        end
        phone = user_response&.string_value
        next if phone.blank?

        content = @push_message.sms_template.content
        response = send_sms(phone, content)
        save_history(phone, :sms, user_input_id, response)
      elsif @push_message.sending_method_email?
        user_response = @scenario_user_responses.find do |each|
          each.data_input_name == 'email' || each.data_input_name == 'user_email'
        end
        email = user_response&.string_value
        next if email.blank?

        response = send_email(email)
        save_history(email, :email, user_input_id, response)
      end
    end
  end

  def send_sms(phone_number, message)
    sms_sender = SmsServices::SmsSender.new
    sms_sender.send(message, phone_number, phone_number)
  end

  def send_email(address)
    template = @push_message.email
    PushMessageMailer.send_email(address, template.subject, template.content).deliver
    return 'success'
  end

  def create_last_message_time_user_reponses
    last_message_time_users = {}
    @scenario_user_responses.each do |each|
      user_input_id = each.user_input_id
      unless last_message_time_users[user_input_id]
        last_message_time_users[user_input_id] = each.created_at
        next
      end
      if last_message_time_users[user_input_id] < each.created_at
        last_message_time_users[user_input_id] = each.created_at
        next
      end
    end
    last_message_time_users
  end

  def save_history(destination, sending_method, user_input_id, reponse)
    history = PushMessageHistory.new(sent_time: Time.now, destination:, sending_method:,
                                     number_of_failed_transmissions: 0, status: :success,
                                     scenario_id: @chatbot.scenario_selected, user_input_id:,
                                     response_data: reponse)
    history.push_message = @push_message
    history.chatbot = @chatbot
    history.save!
  end
end
