Mix.install([:mdex])

IO.puts("Generating HTML Blog")

posts_md_files = Path.wildcard("../blog/????-??-??-*.md") |> Enum.sort()
posts_html_files = posts_md_files |> Enum.map(fn p -> Path.rootname(p) <> ".html" end)

IO.inspect(posts_md_files, label: "posts_md_files")
IO.inspect(posts_html_files, label: "posts_html_files")

if ! File.exists?("blog") do
  File.mkdir!("blog")
end

posts_titles = posts_md_files
|> Enum.map(fn post_md_file ->
  IO.inspect(post_md_file, label: "processing")
  
  mark_down = File.read!(post_md_file)
  md_doc = MDEx.parse_document!(mark_down)
  html_fragment = MDEx.to_html!(md_doc)
  title = md_doc |> Map.get(:nodes) |> List.first() |> Map.get(:nodes) |> List.first() |> Map.get(:literal)

  IO.inspect(title, label: "title")

  post_html_file = "blog/" <> Path.rootname(post_md_file) <> ".html"

  html_header = """
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta http-equiv="X-UA-Compatible" content="ie=edge">
<title>#{title}</title>
<link rel="stylesheet" href="style.css">
</head>
<body>
<div style="text-align: right"><a href="index.html">Index</a></div>
"""
  html_footer = """
</body>
</html>
"""
  html = html_header <> html_fragment <> html_footer
  File.write!(post_html_file, html)
  title
end)

File.cp!("style.css", "blog/style.css")
Path.wildcard("../blog/*.png") |> Enum.each(fn image_file ->
  File.cp!(image_file, "blog/" <> Path.basename(image_file))
end)

html_header = """
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta http-equiv="X-UA-Compatible" content="ie=edge">
<title>Blog</title>
<link rel="stylesheet" href="style.css">
</head>
<body>
<div style="text-align: right">Index</div>
<h1>Blog</h1>
<h5>Yet another blog, a.k.a. some of Sven Van Caekenberghe's writings.</h5>
<h3>2025</h3>
<ul>
"""
  html_footer = """
</ul>
</body>
</html>
"""
  posts_html = Enum.zip(posts_html_files, posts_titles)
|> Enum.map(fn { post_html_file, post_title } ->
  "<li><a href=\"#{post_html_file}\">#{post_title}</a></li>"
end)
|> Enum.join("\n")

html = html_header <> posts_html <> html_footer
File.write!("blog/index.html", html)



