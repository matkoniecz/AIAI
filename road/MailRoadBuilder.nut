class MailRoadBuilder extends BusRoadBuilder
{
}

function MailRoadBuilder::IsAllowed() {
	if (0 == AIAI.GetSetting("use_mail_trucks")) {
		Info("Mail trucks are disabled in AIAI settings.")
		return false;
	}
	return RoadBuilder.IsAllowed();
}

function MailRoadBuilder::GetCargo(){
	return Helper.GetMailCargo();
}

function MailRoadBuilder::GetName(){
	return "mail truck"
}