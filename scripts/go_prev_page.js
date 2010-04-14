(function() {
	var el = document.querySelector("[rel='prev']");
	if (el) {
		location = el.href;
	}
	else {
		var els = document.getElementsByTagName("a");
		var i = els.length;
		while ((el = els[--i])) {
			if (el.text.search(/\bprev|^[<«]|\bzurück\b|\bvorherige\b/i) > -1) {
				location = el.href;
				break;
			}
		}
	}
})();
