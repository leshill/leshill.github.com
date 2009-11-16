
namespace :blog do

  # iterate over all the files in the "templates/blog" folder and create a
  # rake task corresponding to each file found
  FileList["#{Webby.site.template_dir}/blog/*"].each do |template|
    next unless test(?f, template)
    name = template.pathmap('%n')
    next if name =~ %r/^(month|year)$/  # skip month/year blog entries

    desc "Create a new blog #{name}"
    task name do |t|
      page, title, dir = Webby::Builder.new_page_info

      # if no directory was given use the default blog directory (underneath
      # the content directory)
      dir = Webby.site.blog_dir if dir.empty?
      dir = File.join(dir, Time.now.strftime('%Y/%m/%d'))

      page = File.join(dir, File.basename(page))
      page = Webby::Builder.create(page, :from => template,
                 :locals => {:title => title, :directory => dir})
      ::Webby.exec_editor(page)
    end
  end  # each

end  # namespace :blog

# EOF
