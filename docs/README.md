# Documentation documentation

The sub directory dev contains md files which cover various topics around CloudStreet. They are written in plain text using markdown as the markup language for formatting.

## Converting to html, doc and other formats

A utility program called 'pandoc' can be used to convert markdown to anything covered by pandoc really. This includes doc, html, pdf, etc.

Pandoc: <http://johnmacfarlane.net/pandoc/>

An example of using pandoc to covert markdown to html:

    markdown -t html -o file.html file.md

An example of using pandoc to convert all the markdown files to html is as follows:

    find . -name \*.md -type f -exec pandoc -f markdown -t html -o {}.html {} \;

