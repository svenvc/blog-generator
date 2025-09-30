Mix.install([:mdex])

defmodule BlogGenerator do
  def process_post(post_md_file) do
    IO.inspect(post_md_file, label: "processing")

    mark_down = File.read!(post_md_file)
    md_doc = MDEx.parse_document!(mark_down)

    md_doc =
      md_doc
      |> MDEx.traverse_and_update(fn
        %MDEx.Link{url: url} = node ->
          if !String.starts_with?(url, "http") and String.ends_with?(url, ".md") do
            %{node | url: Path.rootname(url) <> ".html"}
          else
            node
          end

        node ->
          node
      end)

    html_fragment = MDEx.to_html!(md_doc)
    title = md_doc |> Enum.at(2) |> Map.get(:literal)
    publication_date = md_doc |> Enum.at(4) |> Map.get(:literal)

    IO.inspect(title, label: "title")
    IO.inspect(publication_date, label: "publication_date")

    post_html_file = "blog/#{Path.rootname(post_md_file)}.html"

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

    File.write!(post_html_file, [html_header, html_fragment, html_footer])
    {Path.basename(post_html_file), title, publication_date}
  end

  def create_index(posts_meta) do
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

    posts_html =
      posts_meta
      |> Enum.map(fn {post_html_file, post_title, publication_date} ->
        "<li><a href=\"#{post_html_file}\">#{post_title}</a> (#{publication_date})</li>"
      end)
      |> Enum.join("\n")

    File.write!("blog/index.html", [html_header, posts_html, html_footer])
  end

  def run do
    IO.puts("Generating HTML Blog")

    if !File.exists?("../blog") do
      throw("you should check out the blog posts next to my directory")
    end

    posts_md_files = Path.wildcard("../blog/????-??-??-*.md") |> Enum.sort()

    IO.puts("#{Enum.count(posts_md_files)} posts to process")

    if !File.exists?("blog") do
      File.mkdir!("blog")
    end

    posts_meta =
      posts_md_files
      |> Enum.map(&process_post/1)

    File.cp!("style.css", "blog/style.css")

    Path.wildcard("../blog/*.png")
    |> Enum.each(fn image_file ->
      File.cp!(image_file, "blog/" <> Path.basename(image_file))
    end)

    create_index(posts_meta)
  end
end

BlogGenerator.run()
