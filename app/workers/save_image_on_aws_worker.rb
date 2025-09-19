require "./lib/node_manager.rb"
class SaveImageOnAWSWorker
  include Sidekiq::Worker

  sidekiq_options queue: :api, retry: false, backtrace: true

  def perform(options)
    begin
      CSLogger.info "=======save_image_on_aws==========="
      key = options["key"]
      img_path_new = options["img_path_new"]
      files_service = ImageService.connection.directories.get(Settings.bucket_name).files
      tempfile = File.read(img_path_new)
      svg_file = files_service.get(key)
      if svg_file
        svg_file.body = tempfile
        svg_file.acl = 'public-read'
        svg_file.save
      else
        files_service.create(
          key:      key,
          acl:      'public-read',
          body:     tempfile,
          content_type: "image/png"
        )
      end
    rescue Exception => e
      CSLogger.error(e.message)
      CSLogger.error(e.backtrace)
    end
  end
end
