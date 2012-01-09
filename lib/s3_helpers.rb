begin
  require 's3'
rescue LoadError
  puts "There is no 's3' gem in Gemfile."
end

if defined?(S3)
    puts "Using \'s3\' gem as Amazon S3 interface."
    def HerokuMongoBackup::s3_connect(bucket, key, secret)
      service = S3::Service.new(:access_key_id     => key,
                                :secret_access_key => secret)
      bucket  = service.buckets.find(bucket)
      return bucket
    end
    def HerokuMongoBackup::s3_upload(bucket, filename)
      object = bucket.objects.build("backups/#{filename}")
      object.content = open(filename)
      object.save
    end
    def HerokuMongoBackup::s3_download(bucket, filename)
      object  = bucket.objects.find("backups/#{filename}")
      content = object.content(reload=true)

      puts "Backup file:"
      puts "  name: #{filename}"
      puts "  type: #{object.content_type}"
      puts "  size: #{content.size} bytes"
      puts "\n"

      return content
    end
  else
    begin
      require 'aws/s3'
    rescue LoadError
      puts "There is no 'aws/s3' gem in Gemfile."
    end

    if defined?(AWS)
      puts "Using \'aws/s3\' gem as Amazon S3 interface."
      def HerokuMongoBackup::s3_connect(bucket, key, secret)
        AWS::S3::Base.establish_connection!(:access_key_id     => key,
                                            :secret_access_key => secret)
        return bucket
      end
      def HerokuMongoBackup::s3_upload(bucket, filename)
        AWS::S3::S3Object.store("backups/#{filename}", open(filename), bucket)
      end
      def HerokuMongoBackup::s3_download(bucket, filename)
        content = AWS::S3::S3Object.value("backups/#{filename}", bucket)
        return content
      end
    else
      puts "Please include 's3' or 'aws/s3' gem in applications Gemfile."
    end
end

