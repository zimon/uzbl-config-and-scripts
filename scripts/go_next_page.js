(function() {
	var el = document.querySelector("[rel='next']");
	if (el) { // Wow a developer that knows what he's doing!
		location = el.href;
	}
	else { // Search from the bottom of the page up for a next link.
		var els = document.getElementsByTagName("a");
		var i = els.length;
		while ((el = els[--i])) {
			if (el.text.search(/\bnext\b|\bmore[\.…]*$|[>»]$|\bnächste\b|\bweiter\b/i) > -1) {
				location = el.href;
				break;
			}
		}
	}
})();
