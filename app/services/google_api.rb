require 'google/cloud/speech'

class GoogleApi
  class << self
    def speech_to_text(filename, current_folder)
      ffmpeg_path = `which ffmpeg`
      puts ffmpeg_path
      puts `ffmpeg -i #{current_folder}/#{filename}.mp3 #{current_folder}/#{filename}.wav`

      Google::Cloud::Speech.configure do |config|
        config.credentials = File.join(current_folder, 'credentials.json')
      end

      client = Google::Cloud::Speech.speech

      audio_file = File.binread(File.join(current_folder, "#{filename}.wav"))

      config = {
          encoding: :LINEAR16,
          sample_rate_hertz: 22050,
          audio_channel_count: 2,
          language_code: "en-US" }

      audio  = { content: audio_file }

      response = client.recognize config: config, audio: audio

      results = response.results

      results.first.alternatives.first.transcript
    end
  end
end
