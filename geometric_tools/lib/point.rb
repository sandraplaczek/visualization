# Copyright (c)  2008 Sandra Placzek (sandra@lifewizz.com)
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use,
# copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following
# conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.

module GeometricTools

   class Point
      attr_accessor :x, :y
       
      def initialize (x ,y)
         @x=x.to_f
         @y=y.to_f
      end
   
      # returns float with the euclidian distance between the passed Points
      def self.euc_distance _point1, _point2
         Math.sqrt((_point2.x-_point1.x)**2 + (_point2.y - _point1.y)**2)
      end

      #Changes the coordinates of a point with the given values. 
      def adjust _x, _y
         x += _x
         y += _y
      end
  
      def is_equal? _another_point
        ((self.x == _another_point.x) && (self.y == _another_point.y))? true : false
      end
   end

end
