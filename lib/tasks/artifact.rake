require "open-uri"

namespace :artifact do

  desc 'Download archival images associated with a file containing a list of pids'
  task :download_images, [:pid_file] => :environment do |t, args|
    puts "Importing images listed in pid file: #{args[:pid_file]}"
    pids = read_pids(args[:pid_file])
    puts pids
    download_files(pids)

    puts "Import finished"
  end

  desc 'Assemble xml import file from previously downloaded objects'
  task :make_xml, [:pid_file] => :environment do |t, args|
    pid_file = args[:pid_file]
    puts "Assembling xml import file for pids in file: #{pid_file}"
    pids = read_pids(pid_file)
    collection_filename = "#{File.dirname(pid_file)}/#{File.basename(pid_file,'.csv')}.xml"
    File.open(collection_filename, 'wb') do |import_xml|
      import_xml.write('<?xml version="1.0"?>' + "\n")
      import_xml.write('<items xmlns:dc      = "http://purl.org/dc/elements/1.1/"' + "\n")
      import_xml.write('       xmlns:dcadesc = "http://nils.lib.tufts.edu/dcadesc/"' + "\n")
      import_xml.write('       xmlns:dcatech = "http://nils.lib.tufts.edu/dcatech/"' + "\n")
      import_xml.write('       xmlns:dcterms = "http://purl.org/dc/terms/"' + "\n")
      import_xml.write('       xmlns:admin   = "http://nils.lib.tufts.edu/dcaadmin/"' + "\n")
      import_xml.write('       xmlns:ac      = "http://purl.org/dc/dcmitype/"' + "\n")
      import_xml.write('       xmlns:rel     = "info:fedora/fedora-system:def/relations-external#"' + "\n")
      import_xml.write('    >  ' + "\n")

      pids.each do |pid|
        import_xml.write("    <digitalObject> \n")
        import_xml.write("        <pid>#{safe_pid(pid)}</pid> \n")
        import_xml.write("        <file>#{filename(pid,'tiff')}</file> \n")
        import_xml.write("        <rel:hasModel>info:fedora/cm:Image.4DS</rel:hasModel> \n")
        import_xml.write("        <admin:displays>tdil</admin:displays> \n")

        # add dca xml contents here
        read_file = File.new(pathname(pid,'dca.xml'), 'r')
        read_file.each_line do |line|
          import_xml.write line unless line.include?('dca_dc:dc')
        end
        read_file.close

        import_xml.write("    </digitalObject> \n")
      end

      import_xml.write("</items> \n")
      import_xml.close
    end


  end

end

def read_pids(pid_file)
  pid_list = []
  read_file = File.new(pid_file, 'r')
  @data_directory = File.dirname(pid_file)
  read_file.each_line {|line| pid_list << line.split(%r{\s*[,\n]\s*})[0] }
  read_file.close
  pid_list
end

def download_files(pid_list)
  pid_list.each do |pid|
    begin
      File.open(pathname(pid,'tiff'), 'wb') do |img_file|
        uri = "http://repository01.lib.tufts.edu:8080/fedora/get/#{pid}/bdef:TuftsArchival/getArchival"
        img_file.write open("http://repository01.lib.tufts.edu:8080/fedora/get/#{pid}/bdef:TuftsArchival/getArchival").read
        img_file.close
      end
      File.open(pathname(pid,'dca.xml'), 'wb') do |dca_meta_file|
        dca_meta_file.write open("http://repository01.lib.tufts.edu:8080/fedora/objects/#{pid}/datastreams/DCA-META/content").read
        dca_meta_file.close
      end
      File.open(pathname(pid,'admin.xml'), 'wb') do |dca_admin_file|
        dca_admin_file.write open("http://repository01.lib.tufts.edu:8080/fedora/objects/#{pid}/datastreams/DCA-ADMIN/content").read
        dca_admin_file.close
      end
      puts("Saved image for #{pid}")
    rescue
      puts "Problem reading #{pid} -- skipping..."
    end
  end
end

def pathname(unescaped_pid, extension)
  "#{@data_directory}/#{filename(unescaped_pid, extension)}"
end

# create filename based on pid without ':'
def filename(unescaped_pid, extension)
  file_safe = unescaped_pid.sub(/:/,'-')
  "#{file_safe}.#{extension}"
end

# Silly method to get rid of 'aah' and dashes in pids until tufts_models and routing is fixed.
def safe_pid(unescaped_pid)
  unescaped_pid.sub(/aah/,'ArtHist').sub(/-/,'.')
end


