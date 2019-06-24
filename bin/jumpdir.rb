require 'getoptlong'
require 'fileutils'

opts = GetoptLong.new(
  [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
  [ '--incdir', '-i', GetoptLong::OPTIONAL_ARGUMENT ],
  [ '--jumpdir', '-j', GetoptLong::OPTIONAL_ARGUMENT ],
  [ '--complete', '-c', GetoptLong::OPTIONAL_ARGUMENT ],
  [ '--markdir', '-m', GetoptLong::OPTIONAL_ARGUMENT ],
  [ '--jumpmark', GetoptLong::OPTIONAL_ARGUMENT ],
  [ '--jumpchild', GetoptLong::REQUIRED_ARGUMENT ]
)

ENV['XDG_DATA_DIR'] = "#{ENV['HOME']}/.local/share" unless ENV['XDG_DATA_DIR'] && !ENV['XDG_DATA_DIR'].empty?
@data_dir = "#{ENV['XDG_DATA_DIR']}/jumpdir"
@data_file = "#{@data_dir}/data.txt"
@marks_file = "#{@data_dir}/marks.txt"
FileUtils.mkdir_p(@data_dir) unless Dir.exist?(@data_dir)

def print_help
  puts <<-EOF
ruby jumpdir.rb [OPTION]

jumpdir is a script to manage and print directories. It can be used in
conjunction with cd to jump to directories around the filesystem.

OPTIONS:

--help, -h:
    show help

--incdir dir, -i dir:
    increase the ranking associate with dir, dir will default to pwd if omitted

--jumpdir keyword, -j keyword:
    print to stdout the highest ranking directory being tracked which matches
    keyword, $HOME will be printed if keyword is omitted

--complete keyword, -c keyword:
    print to stdout all directories being tracked in ranking order which match
    keyword, all directories will be printed if keyword is omitted

--markdir x, -m x:
    associate the directory with the mark x so it can be jumped to using
    --jumpmark x, x must match [0-9a-zA-Z]

--jumpmark x:
    print the directory marked by x

--jumpchild keyword:
    print the first directory which matches keyword and is a child of pwd, BFS
    will be used to find child directories which match

  EOF
end

def inc_dir(dir)
  return if dir == ENV['HOME']

  paths = []
  matched = false

  if File.exist?(@data_file)
    File.open(@data_file) do |f|
      f.each_line do |line|
        path, val = line.split
        val = val.to_i
        if dir == path
          val += 1
          matched = true
        end
        if Dir.exist?(path)
          paths.push [path, val]
        end
      end
    end
  end

  paths.push([ dir, 1 ]) unless matched
  paths.sort! { |a,b| b[1] <=> a[1] }

  File.open(@data_file, 'w') do |f|
    paths.each do |pair|
      f.puts "#{pair[0]} #{pair[1]}"
    end
  end
end

def jump_dir(dir)
  return ENV['HOME'] if dir.empty?

  unless File.exist?(@data_file)
    puts Dir.pwd
    return
  end

  segments = dir.count('/') + 1

  File.open(@data_file) do |f|
    f.each_line do |line|
      path, = line.split
      if "/#{path.downcase.split('/')\
        .last(segments).join('/')}"\
        .include?(dir.downcase)\
      && Dir.exist?(path)
        puts path
        return
      end
    end
  end

  puts Dir.pwd
end

def complete(str)
  return unless File.exists?(@data_file)

  results = []

  File.open(@data_file) do |f|
    f.each_line do |line|
      path, = line.split
      if path.downcase.include?(str.downcase)\
          && Dir.exist?(path)
        results.push path
      end
    end
  end

  puts results.join(' ')
end

def mark_dir(mark)
  return unless mark =~ /\w/

  marks_data = []
  matched = false

  File.open(@marks_file) do |f|
    f.each_line do |line|
      path, tag = line.split
      if tag == mark
        path = Dir.pwd
        matched = true
      end
      marks_data.push [path, tag]
    end
  end if File.exist?(@marks_file)

  marks_data.push([ Dir.pwd, mark ]) unless matched

  File.open(@marks_file, 'w') do |f|
    marks_data.each do |pair|
      f.puts "#{pair[0]} #{pair[1]}"
    end
  end
end

def jump_mark(mark)
  unless mark =~ /\w/ && File.exist?(@marks_file)
    puts Dir.pwd
    return
  end

  File.open(@marks_file) do |f|
    f.each_line do |line|
      path, tag = line.split
      if tag == mark\
          && Dir.exist?(path)
        puts path
        return
      end
    end
  end

  puts Dir.pwd
end

def jump_child(child)
  # Use a Queue instead of Find.find to force BFS
  queue = Queue.new
  queue.push Dir.pwd
  while !queue.empty? do
    dir = queue.pop
    Dir.each_child(dir) do |fname|
      fullpath = "#{dir}/#{fname}"
      if File.directory?(fullpath)
        if fname.downcase.include?(child.downcase)\
            && Dir.exist?(fullpath)
          puts fullpath
          return
        else
          queue.push fullpath
        end
      end
    end
  end

  puts Dir.pwd
end

if ARGV.length == 0
  print_help
  exit 2
end

opts.each do |opt, arg|
  case opt
  when '--help'
    print_help
  when '--incdir'
    if arg.empty?
      inc_dir Dir.pwd
    else
      inc_dir arg
    end
  when '--jumpdir'
    jump_dir arg
  when '--complete'
    complete arg
  when '--markdir'
    mark_dir arg
  when '--jumpmark'
    jump_mark arg
  when '--jumpchild'
    jump_child arg
  end
end
