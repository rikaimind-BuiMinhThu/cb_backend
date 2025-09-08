class ChatbotOpeningBotIconUploader < CarrierWave::Uploader::Base
  storage :file

  def store_dir
    "uploads/chatbot/opening_bot_icon/#{model.id}"
  end

  def extension_allowlist
    %w(jpg jpeg gif png)
  end

  def filename
    "#{Time.now.to_i}.#{file.extension}" if original_filename.present?
  end
end