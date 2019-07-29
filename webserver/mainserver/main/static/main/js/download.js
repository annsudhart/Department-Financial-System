/*
 * download.js
 * This script generates a csv file from the created table 
 * that will be downloaded onto the conputer as results.csv. 
 * The file can be opened in Microsoft Excel.
 * 
 */

 // function that performs the core html table to CSV conversion
function exportToCsv(tableElement) {
    var csv = [];
    var rows = document.querySelectorAll("table tr");
	
    for (var i = 0; i < rows.length; i++) {
		var row = [], cols = rows[i].querySelectorAll("td, th");
		
        for (var j = 0; j < cols.length; j++) {
             // the quotes prevent accidental comma interpretation by the CSV
             // if the table cell text contains a comma.
            row.push('"' + cols[j].innerText + '"');
        }
		csv.push(row.join(","));		
    }

    csvFileString = csv.join('\n');
    csvFile = new Blob([csvFileString], {type: 'text/csv'});

    downloadLink = document.createElement('a');
    downloadLink.download = "results.csv";
    downloadLink.href = window.URL.createObjectURL(csvFile);
    downloadLink.style.display = 'none';
    document.body.append(downloadLink);
    downloadLink.click();
}

// event listener for download button
$('#download').click(function() {
    exportToCsv($('table'));
});