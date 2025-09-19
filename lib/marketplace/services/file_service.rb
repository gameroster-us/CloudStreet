require 'open-uri'
class FileService < CloudStreetService
  S3_BACKUP_PATH = "backups"
  DB_FILE_PATH = "/home/cloudstreet/marketplace-api/files/mongodump.tar.gz"
  RESTORE_PATH = "/data/mount/files/mongodump.tar.gz"
  class << self
    # def get_file(url)
    #   return open(url).read
    # end

    # options keys :local_path, :region,
    #              :s3_properties -> :bucket, :acl, :public
    def upload_directory_to_s3(adapter, options)
      #Assuming sub-contents of directory are all files
      Dir.glob(options[:local_path]) do |file_name|
        file = File.open(file_name,'r')
        return false unless upload_file_to_s3(adapter, file, options)
      end
      true
    end

    # options keys :local_path, :region,
    #              :s3_properties -> :bucket, :acl, :public
    def upload_file_to_s3(adapter, file, options)
      save_file_to_bucket(adapter.connection_storage(options[:region]), file, options[:s3_properties])
      true
      rescue Exception => e
        CSLogger.error("Failed to upload to S3 : "+e.message)
        CSLogger.error(e.backtrace)
      false
    end

    def save_file_to_bucket(connection, tmpfile, options)
      files_service = connection.directories.get(options[:bucket]).files
      file = files_service.get(S3_BACKUP_PATH+tmpfile.path)
      if file
        file.body = tmpfile
        file.acl = options[:acl]
        file.public = options[:public]
        file.save
      else
        files_service.create(
          key:      S3_BACKUP_PATH+tmpfile.path,
          acl:      options[:acl],
          body:     tmpfile,
          public:   options[:public],
          metadata: { content_type: get_content_type(tmpfile) }
        )
      end
    end

    def download_file_from_s3(adapter)
      connection = adapter.connection_storage(Region.find(adapter.bucket_region_id).code)
      files_service = connection.directories.get(adapter.bucket_id).files
      new_db_file = files_service.get(S3_BACKUP_PATH+RESTORE_PATH)
      db_file = files_service.get(S3_BACKUP_PATH+DB_FILE_PATH)
      if db_file.nil? && new_db_file.nil?
        return nil
      else
        backup_path = new_db_file ? RESTORE_PATH : DB_FILE_PATH
        FileUtils.mkdir_p RESTORE_PATH.gsub("mongodump.tar.gz","")
        File.open(RESTORE_PATH,"wb") do |f|
          files_service.get(S3_BACKUP_PATH+backup_path) do |chunk,remaining_bytes,total_bytes|
            f.write chunk
          end
        end
      end
    end

    #TODO: Needs more work to correctly identify the content type
    def get_content_type(file)
      "application/#{File.extname(file).split(".").last}"
    end
  end
end