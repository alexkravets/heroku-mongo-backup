begin
  require 's3'
  
rescue LoadError
    #
    # There is no 's3' gem in Gmefile
    #
    #puts "There is no 's3' gem in Gemfile."
end

if defined?(S3)
    #
    # Using 's3' gem an Amazon S3 interface
    #
    #puts "Using \'s3\' gem as Amazon S3 interface."
    def HerokuMongoBackup::s3_connect(bucket, key, secret)
      service = S3::Service.new(:access_key_id     => key,
                                :secret_access_key => secret)
      bucket  = service.buckets.find(bucket)
      return bucket
    end

    def HerokuMongoBackup::s3_upload(bucket, dirname, filename)
      object = bucket.objects.build("#{dirname}/#{filename}")
      object.content = open(filename)
      object.save
    end

    def HerokuMongoBackup::s3_download(bucket, dirname, filename)
      object  = bucket.objects.find("#{dirname}/#{filename}")
      content = object.content(reload=true)

      puts "Backup file:"
      puts "  name: #{filename}"
      puts "  type: #{object.content_type}"
      puts "  size: #{content.size} bytes"
      puts "\n"

      return content
    end

    def HerokuMongoBackup::remove_old_backup_files(bucket, dirname, files_number_to_leave)
      excess = ( object_keys = bucket.objects.find_all(:prefix => "#{dirname}/").map { |o| o.key }.sort ).count - files_number_to_leave
      (0..excess-1).each { |i| bucket.objects.find(object_keys[i]).destroy } if excess > 0
    end

end



begin
  require 'aws/s3'
rescue LoadError
  #
  # There is no 'aws/s3' in Gemfile
  #
  #puts "There is no 'aws/s3' gem in Gemfile."
end

if defined?(AWS)
  #
  # Using 'aws/s3' gem as Amazon S3 interface
  #
  #puts "Using \'aws/s3\' gem as Amazon S3 interface."
  def HerokuMongoBackup::s3_connect(bucket, key, secret)
    AWS::S3::Base.establish_connection!(:access_key_id     => key,
                                        :secret_access_key => secret)
    return bucket
  end

  def HerokuMongoBackup::s3_upload(bucket, dirname, filename)
    AWS::S3::S3Object.store("#{dirname}/#{filename}", open(filename), bucket)
  end

  def HerokuMongoBackup::s3_download(bucket, dirname, filename)
    content = AWS::S3::S3Object.value("#{dirname}/#{filename}", bucket)
    return content
  end

  def HerokuMongoBackup::remove_old_backup_files(bucket, dirname, files_number_to_leave)
    excess = ( object_keys = AWS::S3::Bucket.find(bucket).objects(:prefix => "#{dirname}/").map { |o| o.key }.sort ).count - files_number_to_leave
    (0..excess-1).each { |i| AWS::S3::S3Object.find(object_keys[i], bucket).delete } if excess > 0
  end

end




begin
  require 'fog'
rescue LoadError
  #
  # There is no 'fog' in Gemfile
  #
  #puts "There is no 'fog' gem in Gemfile."
end

if defined?(Fog)
  #
  # Using 'fog' gem as Amazon S3 interface
  #
  #puts "Using \'fog\' gem as Amazon S3 interface."
  def HerokuMongoBackup::s3_connect(bucket, key, secret)
    connection = Fog::Storage.new({
      :provider                 => 'AWS',
      :aws_access_key_id        => key,
      :aws_secret_access_key    => secret
    })
    directory = connection.directories.new(:key => bucket)
    return directory
  end

  def HerokuMongoBackup::s3_upload(directory, dirname, filename)
    file = directory.files.create(
      :key    => "#{dirname}/#{filename}",
      :body   => open(filename)
    )    
  end

  def HerokuMongoBackup::s3_download(directory, dirname, filename)
    file = directory.files.get("#{dirname}/#{filename}")
    return file.body
  end

  def HerokuMongoBackup::remove_old_backup_files(directory, dirname, files_number_to_leave)
    total_backups = directory.files.all({:prefix => "#{dirname}/"}).size
    
    if total_backups > files_number_to_leave
      
      files_to_destroy = (0..total_backups-files_number_to_leave-1).collect{|i| directory.files.all({:prefix => "#{dirname}/"})[i] }
      
      files_to_destroy.each do |f|
        f.destroy
      end
    end
  end

else
  logging = Logger.new(STDOUT)
  logging.error "\n\nheroku-mongo-backup: Please include 's3', 'aws/s3' or 'fog' gem in applications Gemfile for uploading backup to S3 bucket. (ignore this if using FTP)\n\n"
end




