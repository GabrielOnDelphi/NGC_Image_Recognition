Important note:
1. The above demo program only works with grayscale bitmaps. Convert your JPG/PNG images to BMP.
2. The algorithm cannot search in the first x pixels of the Main image, where x:= Pattern.Width div 2;
Easy fix: If you have an images that has the pattern right on the border on the Main image, you will have to put a fake border around your Main image.