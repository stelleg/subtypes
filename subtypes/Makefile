all: subtypes.pdf

index.html: subtypes.lhs
	pandoc -s -S --toc -c pandoc.css subtypes.lhs -o index.html

subtypes.pdf: subtypes.lhs subtypes.bib 
	pandoc -s --template=default.latex -S subtypes.lhs --natbib -o subtypes.tex
	pdflatex subtypes.tex
	bibtex subtypes
	pdflatex subtypes.tex
	pdflatex subtypes.tex
	grep -v '>' subtypes.lhs | wc -w
	mupdf subtypes.pdf
