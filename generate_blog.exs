Mix.install([:mdex, :lumis],
  config: [mdex_native: [syntax_highlighter: :lumis]])

defmodule BlogGenerator do

  @months ~w(Jan Feb Mar Apr May Jun Jul Aug Sept Oct Nov Dec)

  @options [
    syntax_highlight: [
      engine: :lumis,
      opts: [formatter: {:html_inline, theme: "material_darker"}]]
  ]

  def format_date(%Date{} = date) do
    "#{Enum.at(@months, date.month - 1)} #{date.day}, #{date.year}"
  end

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

    publication_date = Path.basename(post_md_file) |> String.slice(0, 10) |> Date.from_iso8601!()
    title = md_doc |> Enum.at(2) |> Map.get(:literal)
    md_date = MDEx.parse_document!(format_date(publication_date))[1]
    md_doc = md_doc.nodes |> List.insert_at(1, md_date) |> MDEx.Document.wrap

    html_fragment = MDEx.to_html!(md_doc, @options)

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
    <h5>Yet another blog, a.k.a. some of <a href="https://stfx.eu">Sven Van Caekenberghe</a>'s writings.</h5>
    """

    html_footer = """
    </body>
    </html>
    """

    year_groups = Enum.group_by(
      posts_meta,
      fn {_post_html_file, _post_title, publication_date} -> publication_date.year end
    )

    index_html = year_groups
      |> Map.keys()
      |> Enum.sort()
      |> Enum.map(fn year ->
        [
          "<h3>#{year}</h3>\n<ul>\n",
          Map.get(year_groups, year)
          |> Enum.map(fn {post_html_file, post_title, publication_date} ->
            "<li><a href=\"#{post_html_file}\">#{post_title}</a> (#{format_date(publication_date)})</li>\n"
          end),
          "</ul>\n"
        ]
      end)

    # posts_html =
    #   posts_meta
    #   |> Enum.map(fn {post_html_file, post_title, publication_date} ->
    #     "<li><a href=\"#{post_html_file}\">#{post_title}</a> (#{format_date(publication_date)})</li>\n"
    #   end)

    File.write!("blog/index.html", [html_header, index_html, html_footer])
  end

  def run do
    IO.puts("Generating HTML Blog")

    if !File.exists?("../blog") do
      throw("you should check out the blog posts next to my directory")
    end

    posts_md_files = Path.wildcard("../blog/????-??-??-*.md") |> Enum.sort()

    IO.puts("#{Enum.count(posts_md_files)} posts to process")

    if File.exists?("blog") do
      Path.wildcard("blog/*") |> File.rm!()
    else
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
