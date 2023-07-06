function [ m i ] = second_max( x )
   [m i] = max(x(x<max(x)));
end