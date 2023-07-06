function [scaled] = scaledDepths(a, b, array)

%a = minimum;
%b = maximum;

mini = min(array);
maxi = max(array);

scaled = (b-a)*(array-mini)/(maxi-mini)+a;


end
