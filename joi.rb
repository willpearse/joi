#!/usr/bin/ruby

require 'thor'
require 'fileutils'

def make_alias(command, shortcut, terminal_loader, joi_location)
  if File.open(terminal_loader).grep(/joi.rb #{command}/).length==0
    File.open(terminal_loader, 'a') {|x| x << "alias #{shortcut}='#{joi_location} #{command}'\n"}
  end
end

class Joi < Thor
  @@joi_location = "/home/will/Code/joi/joi.rb"
  @@library = "/home/will/Papers/"
  @@terminal_loader = "/home/will/.bashrc"
  
  desc "lib_search TEXT", "Search library for TEXT"
  def lib_search(text, which_open=-1)
    files = Dir.glob(@@library+"**/*")
    results = files.select {|x| x.downcase.include? text.downcase}
    puts "#{results.length} papers found:"
    unless which_open==-1 then job = fork {|x| exec "evince \"#{results[which_open.to_i-1]}\" "} end
    results.each_with_index do |res, i|
      res = res.sub(@@library, "")
      if res.length > 65 then res = res[0..75] + "..." end
      puts " #{i+1} #{res}"
    end
  end

  desc "lib_add FILE LOCATION PERSON YEAR (TITLE)", "Add PDF FILE to library"
  def lib_add(file, location, person, year, title=nil)
    require 'pdf/reader'
    if file[0..3] == "http"
      require 'tempfile'
      require 'open-uri'
      tmp_file_handle = Tempfile.new()
      tmp_file = tmp_file_handle.path
      download = open(file)
      IO.copy_stream(download, tmp_file)
      file = tmp_file
    end
    file = File.expand_path(file)
    unless File.exists?(file)
      puts "#{file} does not exist"
      exit
    end
    if title.nil? then title = PDF::Reader.new(file).info[:Title] end
    if title.nil?
      puts "Title not given and cannot be detected from PDF meta-data"
      exit
    end
    unless Dir.exists?("/home/will/Papers/#{location}")
      puts "/home/will/Papers/#{location} does not exist"
      exit
    end
    outfile = "#{location}/#{person} - #{year} - #{title}"
    puts "Writing to: ~/Papers/#{outfile}"
    FileUtils.cp(file, "/home/will/Papers/#{outfile}.pdf")
  end

  desc "gs_profile PERSON", "Search Google Scholar for PERSON"
  def gs_person(person)
    require 'launchy'
    Launchy.open("https://scholar.google.com/citations?view_op=search_authors&mauthors=#{person.sub(' ','+')}")
  end

  desc "gs_search TEXT", "Search Google Scholar for TEXT"
  def gs_search(text)
    require 'launchy'
    Launchy.open("https://scholar.google.com/scholar?q=#{text.sub(' ','+')}")
  end

  desc "folder_size LOCATION", "Folder sizes at LOCATION (default current directory)"
  def folder_size(location="")
    puts `du -h --max-depth=1`
  end

  desc "disk_use", "How much space are you using?"
  def disk_use(location="")
    puts `df`
  end

  desc "r_pkg_test FOLDER", "Build and test an R package in FOLDER"
  def r_pkg_test(folder="")
    old_pkgs = Dir["./#{folder}*.tar.gz"]
    if old_pkgs.length > 0
      puts "Deleting: #{old_pkgs}"
      old_pkgs.each {|x| File.delete x}
    end
    if Dir.exists? folder
      system "Rscript -e \"library(roxygen2);roxygenize('#{folder}')\""
      system "R CMD build #{folder}"
      package = Dir["./#{folder}*.tar.gz"]
      if package.length > 0
        system "R CMD check #{package[0]} --as-cran"
      end
    else
      puts "No such folder #{folder} to build R package"
    end
  end

  desc "new_ssh USER FULL_NAME PUBLIC_KEY", "Setup a USER's PUBLIC_KEY with their FULL_NAME"
  def new_ssh(user, full_name, public_key)
    if Process.uid == 0
      system "sudo adduser #{user} --disabled-password --gecos '#{full_name}'"
      system "sudo mkdir /home/#{user}/.ssh"
      system "sudo echo #{public_key} > /home/#{user}/.ssh/authorized_keys"
      system "sudo chmod 700 /home/#{user}/.ssh/"
      system "sudo chmod 644 /home/#{user}/.ssh/authorized_keys"
      system "sudo chown #{user}:#{user} /home/#{user}/.ssh/"
      system "sudo chown #{user}:#{user} /home/#{user}/.ssh/authorized_keys"
      system "sudo mkdir /media/bear/#{user}"
      system "sudo mkdir /media/kaiser/#{user}"
      system "sudo chown #{user}:#{user} /media/bear/#{user}"
      system "sudo chown #{user}:#{user} /media/kaiser/#{user}"
      system "sudo ln -s /media/bear/#{user}/ /home/#{user}/bear"
      system "sudo ln -s /media/kaiser/#{user}/ /home/#{user}/kaiser"
    else
      puts "Make me a sandwich (https://xkcd.com/149/)"
    end
  end

  desc "del_usercrib USER", "A reminder of how to delete users but never to be run"
  def del_user_crib(user)
    if Process.uid == 0
      puts "sudo tar -cf /media/kaiser/old-users/USER.tar USER"
      puts "sudo deluser USER"
      puts "sudo rm -rf USER/"
      puts "Decide what to do about kaiser and bear files"
      puts "So help me god, Will, if you just copy-paste the above"
      puts "...you deserve everything that will happen to you..."
    else
      puts "Make me a sandwich (https://xkcd.com/149/)"
    end
  end
  
  desc "bash_aliases", "Set BASH aliases for useful Joi commands"
  def bash_aliases()
    make_alias("", "joi", @@terminal_loader, @@joi_location)
    make_alias("lib_search", "jl", @@terminal_loader, @@joi_location)
    make_alias("gs_person", "jgp", @@terminal_loader, @@joi_location)
    make_alias("gs_search", "jg", @@terminal_loader, @@joi_location)
  end

  desc "new_ms NAME", "Make template for new manuscript with folder NAME"
  def new_ms(name)
    FileUtils.cp_r("/home/will/Code/joi/template-ms/", name)
  end

  desc "new_grant NAME", "Make template for new grant with folder NAME"
  def new_grant(name)
    FileUtils.cp_r("/home/will/Code/joi/template-grant/", name)
  end
end

Joi.start(ARGV)
