(function() {
   clearInformation = function (){
		$('div#more-information').html("");
	};			
				
	addInformation = function(information) {
	
	if ($('div#more-information').text().search(information) == -1){
			$('div#more-information').append(" <a href=#>"+information+" </a>"  );
			
		}
		else {
			
			$('div#more-information a').filter(":contains('"+information+" ')").remove();
      			
		}
	};
})();
