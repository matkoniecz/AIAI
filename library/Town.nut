AILog.Info("adding new functions to SuperLib (Town)");

	//from AIAI by Kogut, based on function from AdmiralAI by Yexo 
	//Plant trees around town town_id to improve rating till it is at least min_rating, stop if amount of available money drops below money_threshold
	//return true on success (rating is at least as high as min_rating), false otherwise
	//PlantTreesToImproveRating(town_id, min_rating, money_threshold)

_SuperLib_Town.PlantTreesToImproveRating <- function(town_id, min_rating, money_threshold) {
	/* Build trees to improve the rating. We build this tree in an expanding
	 * circle starting around the town center. */
	local location = AITown.GetLocation(town_id);
	local list = SuperLib.Tile.GetTownTiles(town_id)
	list.Valuate(AITile.IsBuildable);
	list.KeepValue(1);
	/* Don't build trees on tiles that already have trees, as this doesn't
	 * give any town rating improvement. */
	list.Valuate(AITile.HasTreeOnTile);
	list.KeepValue(0);
	foreach (tile, dummy in list) {
		if (AITown.IsWithinTownInfluence(town_id, tile)) {
			if (!AITile.PlantTree(tile)) {
				if (AIError.GetLastError() == AIError.ERR_NOT_ENOUGH_CASH) {
					return (AITown.GetRating(town_id, AICompany.COMPANY_SELF) >= min_rating);
				}
			}
		}
		/* Check whether the current rating is good enough. */
		if (AITown.GetRating(town_id, AICompany.COMPANY_SELF) >= min_rating) {
			return true;
		}
		if (AICompany.GetBankBalance(AICompany.COMPANY_SELF) < money_threshold) {
			return false;
		}
	}
	if (AITown.GetRating(town_id, AICompany.COMPANY_SELF) >= min_rating) {
		return true;
	} else {
		return false;
	}
}

AILog.Info("changing SuperLib (Town) finished");
