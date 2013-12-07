/**
 *  modified path from the AyStar algorithm library
 *  The last entry has a GetParent() of null.
 */
class Path
{
	_prev = null;
	_next = null;
	_tile = null;
	_direction = null;
	_cost = null;
	_length = null;
	_real_length = null;

	constructor(old_path, new_tile, new_direction)
	{
		this._prev = old_path;
		this._tile = new_tile;
		this._direction = new_direction;
		if (old_path == null) {
			this._length = 0;
			this._real_length = 0.0;
		} else {
			old_path._next = this;
			this._length = old_path.GetLength() + AIMap.DistanceManhattan(old_path.GetTile(), new_tile);
			if (old_path.GetParent() != null)
				{
				local old_tile = old_path.GetTile();
				local very_old_tile = old_path.GetParent().GetTile();
				if (new_tile - old_tile != old_tile - very_old_tile) {
					this._real_length = old_path._real_length + 0.5;
					}
				else{
					this._real_length = old_path._real_length + 1.0;
					}
				}
			else
				{
				this._real_length = 0.0;
				}
		}
	//local mode = AIExecMode();
	//AISign.BuildSign(new_tile, this._real_length);
	};

	/**
	 * Return the tile where this (partial-)path ends.
	 */
	function GetTile() { return this._tile; }

	/**
	 * Return the direction from which we entered the tile in this (partial-)path.
	 */
	function GetDirection() { return this._direction; }

	/**
	 * Return an instance of this class leading to the previous node.
	 */
	function GetParent() { return this._prev; }

	/**
	 * Return an instance of this class leading to the next node.
	 */
	function GetChildren() { return this._next; }

	/**
	 * Return the length (in tiles) of this path.
	 */
	function GetLength() { return this._length; }
	/**

	* Return the length (in tiles) of this path.
	 */
	function GetRealLength() 
	{ 
	if (this.GetParent() == null) return 0;
	return this.GetParent()._real_length; 
	}
};
