<?php
class vw
{
    public function vw() {
        require('xmlLib.php');
        require('vw-cfg.php');

        $this->methodTable = array( 
            "getXML" => array(
                "description" => "returns the XML File Contents as flash String",
                "access" => "remote",
                "returns" => "Object"
            ),
            "getResults" => array(
                "description" => "returns the XML File Contents as an associative Array",
                "access" => "remote",
                "returns" => "Array"
            ),
            "getVideoDB" => array(
                "description" => "returns the DB Contents as an ArrayCollection",
                "access" => "remote",
                "returns" => "ArrayCollection"
            ),
            "getMysqlResults" => array(
                "description" => "returns the DB Contents as an associative Array",
                "access" => "remote",
                "returns" => "Array"
            )
        );
    }

    // Use MYSQL Database for Videos, get ICollectionArray results
    public function getVideoDB($sMessage)
    {
         if ($sMessage == '')
                $sMessage = '.*';
         $data_results = array('No Results Found');

         mysql_connect($this->MYSQL_DB_URL, $this->MYSQL_DB_USR, $this->MYSQL_DB_PWD);
         mysql_select_db('vw');

         $q = "SELECT location, image, annotation FROM videos ";
         $q.="where UCASE(annotation) REGEXP UCASE('%s') or ";
         $q.="UCASE(location) REGEXP UCASE('%s') or UCASE(image) REGEXP UCASE('%s') ";
         $q.="LIMIT 10000";
         $query = sprintf($q, $sMessage, $sMessage, $sMessage);

         $result = mysql_query($query);
         if (!$result)
                return $data_results;
         else
                return $result;
    }

    // Use MYSQL Database for Videos, turn results into an associative array
    public function getMysqlResults($sMessage)
    {
         $data_results = array('No Results Found');
         $result = $this->getVideoDB($sMessage);
         if (!$result)
                return $data_results;
         $i=0;
         while ($row = mysql_fetch_assoc($result)) {
             $data_results[$i++] = $row;   
         }
         return $data_results;
    }

    // Use XML Database for Videos, Return as an associative array
    public function getResults($sMessage)
    {
        $data_results = array();

        if ($sMessage == '')
                $sMessage = '.*';
        $searchPattern = '/' . $sMessage . '/';
        $searchPattern = strtoupper($searchPattern);

        for($i=0, $x=0; $i < count($this->data_sources); $i++) {
                $xml = new XMLToArray($this->data_sources[$i],
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

    // Use XML Database for Videos, Return as an XML file string
    public function getXML($sMessage)
    {
        $returnString = $this->getResults($sMessage);
        $array = new ArrayToXML($returnString);

        // Top XML Header
        $TOPXML ="<?xml version=\"1.0\" encoding=\"utf-8\"?>\n";
        $TOPXML.="<playlist version=\"1\" xmlns=\"http://xspf.org/ns/0/\">\n<tracklist>\n";

        // Bottom XML End
        $BOTTOMXML="</tracklist>\n</playlist>";

        // Top of XML
        $xmlData = "$TOPXML";

        // Main XML
        $xmlData .= $array->getXML();

        // XML Footer
        $xmlData .= "$BOTTOMXML";

        $xmlData = preg_replace('/<>/', "<track>\n", $xmlData);
        $xmlData = preg_replace('/<\/>/', "</track>", $xmlData);

        return $xmlData;
    }
}
?>
