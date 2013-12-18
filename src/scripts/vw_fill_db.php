<?php
    require('xmlLib.php');

    function getResults($sMessage)
    {
        $data_results = array();

        if ($sMessage == '')
                $sMessage = '.*';
        $searchPattern = '/' . $sMessage . '/';
        $searchPattern = strtoupper($searchPattern);

        // XML Databases to search
        $data_sources = array(
                'http://digit.groovy.org/naruto.xml',
                'http://alpha.groovy.org/u1/video.xml',
                'http://alpha.groovy.org/VW/012709.xml',
                'http://alpha.groovy.org/VW/thumbs.xml',
        );

        for($i=0, $x=0; $i < count($data_sources); $i++) {
                $xml = new XMLToArray($data_sources[$i],
                        array('playlist','tracklist'), 
                        array('track' => '_array_'), false, false);

                $xml_array = $xml->getAmpArray();

                for ($z=0; $z < count($xml_array); $z++) {
                        if (preg_match($searchPattern, strtoupper($xml_array[$z]['annotation'])) ||
                                preg_match($searchPattern, strtoupper($xml_array[$z]['image'])) ||
                                preg_match($searchPattern, strtoupper($xml_array[$z]['location'])))
                                        $data_results[$x++] = $xml_array[$z];
                }
        }

        return $data_results;
    }

    $data_results = (getResults('.*'));

    mysql_connect('localhost', 'vw', 'videowall');
    mysql_select_db('vw');
    for ($z=0; $z < count($data_results); $z++) {
        //print("$z " . $data_results[$z]['location'] . "\n");
        //print("$z " . $data_results[$z]['image'] . "\n");
        //print("$z " . $data_results[$z]['annotation'] . "\n");
        $q = "INSERT INTO videos (id, location, image, annotation) ";
        $q.= "values (0, '" . $data_results[$z]['location'] . "', '";
        $q.= $data_results[$z]['image'] . "', '";
        $q.= $data_results[$z]['annotation'] . "')";
        $result = mysql_query($q);
        if (!$result) {
                print(mysql_error());
                print ("$q\n");
        }
    }
?>
