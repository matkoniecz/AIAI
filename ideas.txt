ideas 
function Banker::GetInflationRate() //from simpleai
{
	return (100 * AICompany.GetMaxLoanAmount() / AIGameSettings.GetValue("difficulty.max_loan"));
}