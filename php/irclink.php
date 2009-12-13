<?php
/*
  All purpose ircd_linkbot parser.
 */
/* Configuration */
$filename = '/path/to/network_links.json';
/* End Configuration */
$mtime = date ("r", filemtime($filename));
$fh = fopen($filename, 'r');
$json = fread($fh, filesize($filename));
fclose($fh);
//var_dump(json_decode($json, true));
$arr = json_decode($json);
print '<table class="irc_stats">';
?>
<tr>
    <td class="server_1" colspan="2"> Server List as of <?php echo $mtime ?></td>
</tr>
<?php
foreach($arr as $a) {
    print '<tr>';
    print '<td class="server_1">';
    print $a->{'name'};
    print "</td>\n";
    print '<td class="server_1">';
    print $a->{'uptime'};
    print "</td>\n";
    print "</tr>\n";
}
print '</table>';
?>
