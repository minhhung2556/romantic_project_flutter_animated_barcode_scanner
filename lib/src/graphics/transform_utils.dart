import 'dart:ui';

extension TransformUtils on Offset{
 Offset toRect(Rect source, Rect destination){
   double x = ...; // Point x-coordinate within R1
   double y = ...; // Point y-coordinate within R1

   double xNormalized = (x - a) / (c - a);
   double yNormalized = (y - b) / (d - b);

   double xTransformed = e + xNormalized * (g - e);
   double yTransformed = f + yNormalized * (h - f);
   return this;
 }
}