################################################################################
# Compile SASS to CSS
css_filename = 'application'

system("sass #{css_filename}.scss #{css_filename}.css")

################################################################################
# Insert all SVG icons into index.html
app_folder = 'icons_seperate_css'

html_template = "#{app_folder}/template.html"
html_renderer = "#{app_folder}/external_css.html"

icons_path = "#{app_folder}/icons/*"

lines = File.readlines(html_template)
insert_index = lines.find_index { |line| line.include?(" {{YIELD}}\n") }

svg_lines = []
Dir.glob(icons_path).each do |icon_file|
  svg_lines << File.readlines(icon_file)
end

lines[insert_index] = svg_lines
lines.flatten!

File.open("#{html_renderer}", 'w+') { |f| f.write(lines.join) }




################################################################################
# Build icons_inline_css

icons_inline_path = "icons_inline_css/icons"
icons_inline_styles = "icons_inline_css/styles/icons"

base_scss_path =  "icons_seperate_css/styles/base.scss"
keyframes_path = "icons_seperate_css/styles/keyframes"

Dir.glob(icons_path).each do |icon_file|
  next if icon_file.include?('_all.scss')

  icon_filename = File.basename(icon_file)
  icon_scssname = icon_filename.gsub('svg', 'scss')
  icon_cssname = icon_filename.gsub('svg', 'css')



  icon_lines = File.readlines(icon_file)
  insert_style_index = icon_lines.find_index { |line| line.include?("<style></style>\n") }

  style_lines = File.readlines(icon_file.gsub('/icons/', '/styles/icons/').gsub('svg', 'scss'))

  base_lines = File.readlines(base_scss_path)

  # Find necessary Keyframes
  keyframes = style_lines.find { |line| line.include?("// Animations:") }
                         .gsub('// Animations:', '')
                         .strip
                         .split(',')

  keyframe_lines = []
  keyframes.each do |keyframe|
    keyframe_lines << File.readlines("#{keyframes_path}/#{keyframe.strip}.scss")
  end

  # Build Style Array
  style = base_lines
  style << style_lines
  style << keyframe_lines
  style.flatten!

  # save to scss
  File.open("#{icons_inline_styles}/#{icon_scssname}", 'w+') { |f| f.write(style.join) }



  # render to css
  system("sass #{icons_inline_styles}/#{icon_scssname} #{icons_inline_styles}/#{icon_cssname}")



  # style = css
  css_style_lines = ["<style>\n"]
  css_style_lines << File.readlines("#{icons_inline_styles}/#{icon_cssname}")
  css_style_lines << ["</style>\n"]

  icon_lines[insert_style_index] = css_style_lines
  icon_lines.flatten!

  File.open("#{icons_inline_path}/#{File.basename(icon_file)}", 'w+') { |f| f.write(icon_lines.join) }
end

app_folder = 'icons_inline_css'

html_template = "#{app_folder}/template.html"
html_renderer = "#{app_folder}/inline_css.html"

icons_path = "#{app_folder}/icons/*"

lines = File.readlines(html_template)
insert_index = lines.find_index { |line| line.include?(" {{YIELD}}\n") }

svg_lines = []
Dir.glob(icons_path).each do |icon_file|
  icon_filename = File.basename(icon_file)

  svg_lines << "<img src='icons_inline_css/icons/#{icon_filename}' alt='#{icon_filename.gsub('.svg','').gsub('_', ' ')}'>\n"
end

lines[insert_index] = svg_lines
lines.flatten!

File.open("#{html_renderer}", 'w+') { |f| f.write(lines.join) }


################################################################################
# Combine to index.html

html_template = "index_template.html"
html_renderer = "index.html"

lines = File.readlines(html_template)

insert_index = lines.find_index { |line| line.include?(" {{YIELD}}\n") }

html_lines = File.readlines('icons_seperate_css/external_css.html')
html_lines << File.readlines('icons_inline_css/inline_css.html')

lines[insert_index] = html_lines.flatten

File.open("#{html_renderer}", 'w+') { |f| f.write(lines.join) }
