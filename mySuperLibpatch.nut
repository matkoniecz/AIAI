AILog.Info("changing SuperLib");

//from Rondje, computes square root of i using Babylonian method
_SuperLib_Helper.Sqrt <- function(i) 
{ 
	assert(i>=0);
	if (i == 0) {
		return 0; // Avoid divide by zero
	}
	local n = (i / 2) + 1; // Initial estimate, never low
	local n1 = (n + (i / n)) / 2;
	while (n1 < n) {
		n = n1;
		n1 = (n + (i / n)) / 2;
	}
	return n;
}

AILog.Info("changing SuperLib finished");
