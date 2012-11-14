(function() {
   clearInformation = function (){
		$('div#more-information').html("");
	};			
				
	addInformation = function(information) {
	if ($('div#more-information').text().search(information) == -1){
			$('div#more-information').append(" "+information);
		}
		else {
			$('div#more-information').html($('div#more-information').html().replace(" "+information, ""));
		}
	};
})();
