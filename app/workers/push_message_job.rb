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
    puts "PushMessageJob scenario_user_responses.length: #{@scenario_user_responses.length}"
    return if @scenario_user_responses.length === 0

    last_message_time_user_responses = create_last_message_time_user_reponses

    puts "PushMessageJob last_message_time_user_responses: #{last_message_time_user_responses}"

    last_message_time_user_responses.each do |user_input_id, value|
      next if value + @push_message.last_message_datetime_since * 60 > Time.now

      user_responses = @scenario_user_responses.select { |each| each.user_input_id == user_input_id }

      if @push_message.has_timezone_exclusion_yes? && @push_message.excluded_time_from < Time.now.hour &&
         Time.now.hour < @push_message.excluded_time_to &&
         Time.now.hour != @push_message.alternate_send_time
        return
      end

      @push_message.push_message_variables.each do |each|
        value = find_response_by_data_input_name(each.variable.name)
        case each.operator
        when 'is'
          if(value == each.value)
            return
          end
        when 'is_not'
          if(value != each.value)
            return
          end
        when 'contains'
          unless (value.to_s.include?each.value)
            return
          end
        end
      end

      if @push_message.sending_method_sms?
        phone = find_response_by_data_input_name(["phone", "phone_number"])
        next if phone.blank?

        content = @push_message.sms_template.content
        response = send_sms(phone, content)
        save_history(phone, :sms, user_input_id, response)
      elsif @push_message.sending_method_email?
        email = find_response_by_data_input_name(["email", "user_email"])
        next if email.blank?

        response = send_email(email)
        save_history(email, :email, user_input_id, response)
      end
    end
  end

  def send_sms(phone_number, message)
    puts "PushMessageJob send sms"
    sms_sender = SmsServices::SmsSender.new
    sms_sender.send(message, phone_number, phone_number)
  end

  def send_email(address)
    puts "PushMessageJob send email"
    template = @push_message.email
    PushMessageMailer.send_email(address, template.subject, template.content).deliver
    'success'
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
    puts "PushMessageJob save_history"
    history = PushMessageHistory.new(sent_time: Time.now, destination:, sending_method:,
                                     number_of_failed_transmissions: 0, status: :success,
                                     scenario_id: @chatbot.scenario_selected, user_input_id:,
                                     response_data: reponse)
    history.push_message = @push_message
    history.chatbot = @chatbot
    history.save!
  end

  def get_user_data_input data_input_name
    @scenario_user_responses.find do |each|
      if data_input_name.is_a?(String) 
        return each.data_input_name == data_input_name
      elsif data_input_name.is_a?(Array)
        return data_input_name.include? each.data_input_name
      else
        return false
      end
    end
  end

  def find_response_by_data_input_name(data_input_name)
    response = @scenario_user_responses.detect do |each|
      if data_input_name.is_a?(String) 
        return each.data_input_name == data_input_name
      elsif data_input_name.is_a?(Array)
        return data_input_name.include? each.data_input_name
      else
        return false
      end
    end
    return response&.value
  end
end
