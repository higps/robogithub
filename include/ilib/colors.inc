#include <sdktools>

#if defined _ilib_colors_included
 #endinput
#endif
#define _ilib_colors_included

/*
* Wrapper for color integer arrays
*/
enum struct FLinearColor
{
	int R;
	int G;
	int B;
	int A;

	//Converts this LinearColor into an integer array
	int[] Get()
	{
		int color[4];

		color[0] = this.R;
		color[1] = this.G;
		color[2] = this.B;
		color[3] = this.A;

		return color;
	}

	void Set(int r, int g, int b, int a)
	{
		this.R = r;
		this.G = g;
		this.B = b;
		this.A = a;
	}
	
	void Scale(float factor)
	{
		this.R = RoundToFloor(float(this.R) * factor);
		this.G = RoundToFloor(float(this.G) * factor);
		this.B = RoundToFloor(float(this.B) * factor);
	}
}
