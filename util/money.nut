function RepayOnePieceOfLoan()
{
	return AICompany.SetLoanAmount(AICompany.GetLoanAmount()-AICompany.GetLoanInterval())
}

function BorrowOnePieceOfLoan()
{
	return AICompany.SetLoanAmount(AICompany.GetLoanAmount()+AICompany.GetLoanInterval())
}

function GetSafeBankBalance()
{
	local minimum = Money.Inflate(20000)
	minimum +=  AIInfrastructure.GetMonthlyInfrastructureCosts(AICompany.COMPANY_SELF,  AIInfrastructure.INFRASTRUCTURE_RAIL)
	minimum +=  AIInfrastructure.GetMonthlyInfrastructureCosts(AICompany.COMPANY_SELF,  AIInfrastructure.INFRASTRUCTURE_ROAD)
	minimum +=  AIInfrastructure.GetMonthlyInfrastructureCosts(AICompany.COMPANY_SELF,  AIInfrastructure.INFRASTRUCTURE_CANAL)
	minimum +=  AIInfrastructure.GetMonthlyInfrastructureCosts(AICompany.COMPANY_SELF,  AIInfrastructure.INFRASTRUCTURE_AIRPORT)
	return minimum
}

function GetAvailableMoney()
{
	local money = AICompany.GetBankBalance(AICompany.COMPANY_SELF)
	if (money > money + AICompany.GetMaxLoanAmount()) {
		return 2147483647 //implied by _intsize_ = 4 on 32bit architecture
	}
	money = money + AICompany.GetMaxLoanAmount()
	money = money - AICompany.GetLoanAmount() - GetSafeBankBalance()
	return money;
}

function BankruptProtector()
{
	local needed_pocket_money = GetSafeBankBalance();
	while(AICompany.GetBankBalance(AICompany.COMPANY_SELF)<0) {
		if (AIBase.RandRange(10)==1) {
			Error("We need bailout!");
		} else {
			Error("We need money!");
		}
		while(AICompany.GetBankBalance(AICompany.COMPANY_SELF)<0) {
			if (AICompany.GetLoanAmount()==AICompany.GetMaxLoanAmount()) {
				Error("We are too big to fail! Remember, we employ " + (AIVehicleList().Count()*7+AIStationList(AIStation.STATION_ANY).Count()*3+23) + " people!");
				DoomsdayMachine();
				Sleep(1000);
			}
			BorrowOnePieceOfLoan()
		}
		Info("End of financial problems!");
	}
	while(AICompany.GetBankBalance(AICompany.COMPANY_SELF)< needed_pocket_money){
		if (!BorrowOnePieceOfLoan()){
			Error("We need money! ("+AICompany.GetBankBalance(AICompany.COMPANY_SELF)+"/"+needed_pocket_money+")");
			Helper.SellAllVehiclesStoppedInDepots();
			Sleep(1000);
		}
	}
}

function ProvideMoney(amount = null)
{
	if (AICompany.GetBankBalance(AICompany.COMPANY_SELF)>10*AICompany.GetMaxLoanAmount()) {
		Money.MakeMaximumPayback();
	} else {
		Money.MaxLoan();
	}

	if (amount != null) {
		while(AICompany.GetBankBalance(AICompany.COMPANY_SELF) - 3*AICompany.GetLoanInterval() > amount && AICompany.GetLoanAmount() != 0) {
		RepayOnePieceOfLoan();
		Info("Loan rebalanced to " + AICompany.GetLoanAmount());
		}
	}
}
