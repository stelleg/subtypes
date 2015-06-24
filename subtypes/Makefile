all: subtypes.pdf

index.html: hm_scott.lhs
	pandoc -s -S --toc -c pandoc.css hm_scott.lhs -o index.html

subtypes.pdf: hm_scott.lhs
	pandoc -s --template=default.latex -S hm_scott.lhs -o subtypes.tex
	pdflatex subtypes.tex
	pdflatex subtypes.tex
