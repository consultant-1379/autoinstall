package com.ericsson.nms.litp.taf.autoinstall.test.cases;

import java.io.*;
import java.io.File;
import java.io.IOException;
import java.util.List;

import org.apache.commons.io.FileUtils;

import org.apache.log4j.Logger;
import org.testng.annotations.Test;

import java.net.InetAddress;
import java.net.UnknownHostException;


//import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.CoreMatchers.containsString;

import com.ericsson.cifwk.taf.TorTestCaseHelper;
import com.ericsson.cifwk.taf.annotations.TestId;
import com.ericsson.cifwk.taf.tools.cli.TimeoutException;
import com.ericsson.cifwk.taf.handlers.implementation.LocalCommandExecutor;
import com.ericsson.cifwk.taf.utils.FileFinder;
import com.ericsson.cifwk.taf.data.*;

import com.ericsson.nms.litp.taf.operators.AutoUpgradeRunner;
//import com.ericsson.nms.litp.taf.operators.ExpansionRunner;

import java.io.FileNotFoundException;

import javax.inject.Inject;

public class AutoInstallRunner extends TorTestCaseHelper {

    Logger logger = Logger.getLogger(AutoInstallRunner.class);
    
    /**
     * @throws TimeoutException,FileNotFoundException
     * @DESCRIPTION Testing a simple test case for CDB
     * @PRE Connection to SUT
     * @PRIORITY HIGH
     */
    
    @TestId(id = "LITP2_autoinstall", title = "Auto install LITP 2 in cloud")
    @Test(groups={"Acceptance"})
    public void autoInstallLITP2() {

        System.out.println("Starting TAF test case");

        // This Is what is needed to flush the output from autoinstall python to the screen as received
        Host host = DataHandler.getHostByName("ms1");
        System.out.println("Starting TAF test case"); 
        String installType = System.getenv("installType") != null ? System.getenv("installType") : "cloud";
        String deployType = System.getenv("deployType") != null ? System.getenv("deployType") : "CLI";
        List<String> fileNames = FileFinder.findFile("autoinstall.py");
        String autoinstallLocationPath = fileNames.get(0).replace("autoinstall.py", "");
        System.out.println("Autoinstall script location path:"); 
        System.out.println(autoinstallLocationPath);
        File dir = new File(".");
        String[] extensions1 = new String[] { "iso"};
        List<File> isoNames = (List<File>) FileUtils.listFiles(dir, extensions1, true);
        String[] extensions2 = new String[] { "gz"};
        List<File> coreNames = (List<File>) FileUtils.listFiles(dir, extensions2, true);
        String[] extensions3 = new String[] { "rpm"};
        List<File> ipmiNames = (List<File>) FileUtils.listFiles(dir, extensions3, true);
        //String clusterfile = null;
        //String deployscript = null;
        String installOption = null;
        String litpClusterFile = System.getenv("litpClusterFile") != null ? System.getenv("litpClusterFile") : "/clusterfiles/multiblade_san/10.44.86.100_cdb.sh";
        String litpInstallScript = System.getenv("litpInstallScript") != null ? System.getenv("litpInstallScript") : "/installscripts/multiblade_san/deploy_multiblade_san.sh";
        if (installType.contains("cloud")){
            //clusterfile = "192.168.0.42.sh";
            //deployscript = "deploy_cloud.sh";
            installOption = "-rhellitp";
        }
        else{
            //clusterfile = "10.44.86.100_cdb.sh";
            //deployscript = "deploy_multiblade_san.sh";
            installOption = "-ci";
        }
        //System.out.println(clusterfile);
        //System.out.println(deployscript);
        System.out.println(installOption);

        //List<String> clusterNames = FileFinder.findFile("192.168.0.42.sh");
        //List<String> clusterNames = FileFinder.findFile(clusterfile);
        //List<String> installNames = FileFinder.findFile(deployscript);
        String autoinstallLocation = fileNames.get(0);
        System.out.println("Autoinstall script:"); 
        System.out.println(autoinstallLocation);
        File litpIsoLocation = null;
        for (File child : isoNames){
            String compare = null;
            compare = child.getAbsolutePath();//FileUtils.readFileToString(child);
            System.out.println("Compare: " + compare);
            if (compare.contains("ERIClitp_CXP9024296") && compare.endsWith(".iso")){
                litpIsoLocation = child;
                break;
            }
        } 
        System.out.println("ISO To install"); 
        System.out.println(litpIsoLocation); 

        File coreLocation = null;
        for (File child : coreNames){
            String compare = null;
            compare = child.getAbsolutePath();//FileUtils.readFileToString(child);
            System.out.println("Compare: " + compare);
            if (compare.contains("core-3pps") && compare.endsWith(".gz")){
                coreLocation = child;
                break;
            }
        } 
        System.out.println("Tarball 3pp location"); 
        System.out.println(coreLocation); 

        File ipmiLocation = null;
        for (File child : ipmiNames){
            String compare = null;
            compare = child.getAbsolutePath();//FileUtils.readFileToString(child);
            System.out.println("Compare: " + compare);
            if (compare.contains("IPMICloudHelperTool") && compare.endsWith(".rpm")){
                ipmiLocation = child;
                break;
            }
        } 
        System.out.println("IMPI RPM:"); 
        System.out.println(ipmiLocation); 
        //String litpClusterFile = clusterNames.get(0);
        litpClusterFile = autoinstallLocationPath + "/" + litpClusterFile;
        System.out.println("Clusterfile location");
        System.out.println(litpClusterFile);
        //String litpInstallScript = installNames.get(0);
        litpInstallScript = autoinstallLocationPath + "/" + litpInstallScript;
        System.out.println("Installation script"); 
        System.out.println(litpInstallScript); 

        String resultsDir = autoinstallLocation.replace("autoinstall.py", "");
        //String rhelISO = "/var/www/html/rhel-server-6.4-x86_64-dvd.iso";
        String runCmd = null;
        String ipFind = "hostname -i";
        String[] ipAddresseeth1 = null;
        String message = new String();
        try {
            Process kl = Runtime.getRuntime().exec(ipFind);
            BufferedReader stdOut = new BufferedReader( new InputStreamReader(kl.getInputStream()) );
            BufferedReader stdErr = new BufferedReader( new InputStreamReader(kl.getErrorStream()) );
            String ni = null;
            int counter = 0;
            while ((ni = stdOut.readLine()) != null) {
                //ipAddresseeth1[counter] = ni;
                //counter += 1;
                message += ni;
                //System.out.println(ni);
            }
            //String ti = null;
            //while ((ti = stdErr.readLine()) != null) {
                //System.out.println(ti);
            //}
            kl.waitFor();
            stdOut.close();
            stdErr.close();
            //System.out.print(str(stdOut[0]));
        }
        catch (Exception err) {
            err.printStackTrace();
        }
        System.out.println(message);
        String httpLink = "http://" + message + ":80/";
        //String rhelLink = httpLink + "rhel-server-6.4-x86_64-dvd.iso";
        String rhelLink = httpLink + "rhel-server-6.6-x86_64-dvd.iso";
        //String osPatchesOption = "--with_os_patches=http://10.44.86.30/iso/RHEL_Patches/6.6_RevL/RHEL_OS_Patch_Set_CXP9026826-3.0.18.tar.gz";
        String osPatchesOption = "--with_os_patches=http://10.44.86.30/iso/RHEL_Patches/6.6_RevM/RHEL_OS_Patch_Set_CXP9026826-3.0.21.tar.gz";
        String httpServer = "/var/www/html/";

        if (installType.contains("cloud")){
            try(PrintWriter out = new PrintWriter(new BufferedWriter(new FileWriter(litpClusterFile, true)))) {
                out.println("ntp_ip[1]=172.16.30.1");
                //out.println("ntp_ip[1]=" + message);
            }catch (IOException err) {
               err.printStackTrace();
            }
            runCmd = "/usr/bin/python " + autoinstallLocation + " " + installOption + " --litpiso=" + litpIsoLocation + " --thirdpp=" + coreLocation + " --install_type=" + installType + " --server_http_full_path_location=" + resultsDir + " --cluster_file=" + litpClusterFile + " --install_script=" + litpInstallScript + " --ipmi_tool_location=" + ipmiLocation + " --install_option=" + deployType;
        }
        else{
            runCmd = "/usr/bin/python " + autoinstallLocation + " " + installOption + " --rheliso=" + rhelLink + " --litpiso=" + litpIsoLocation + " --thirdpp=" + coreLocation + " --install_type=" + installType + " --cluster_file=" + litpClusterFile + " --install_script=" + litpInstallScript + " --server_http_location=" + httpLink + " --server_http_full_path_location=" + httpServer + " " + osPatchesOption + " --install_option=" + deployType;
        }
        logger.debug("Running command:" + runCmd);
        try {
            System.out.println("");
            System.out.println("");
            System.out.println("");
            Process p = Runtime.getRuntime().exec(runCmd);
            BufferedReader stdOut = new BufferedReader( new InputStreamReader(p.getInputStream()) );
            BufferedReader stdErr = new BufferedReader( new InputStreamReader(p.getErrorStream()) );
            System.out.println("---------------------------------"); 
            System.out.println("stdout output"); 
            System.out.println("---------------------------------"); 
            String s = null;
            while ((s = stdOut.readLine()) != null) {
                System.out.println(s);
            }
            System.out.println("---------------------------------"); 
            System.out.println("stderr output"); 
            System.out.println("---------------------------------"); 
            String t = null;
            while ((t = stdErr.readLine()) != null) {
                System.out.println(t);
            }
            System.out.println("---------------------------------"); 
            System.out.println("Return code");
            System.out.println("---------------------------------");
            p.waitFor();
            System.out.println(p.exitValue());
            stdOut.close();
            stdErr.close();
            System.out.println("");
            System.out.println("");
            System.out.println("");
            System.out.println("---------------------------------"); 
            //assertEquals("", stdErr);
            assertTrue("ERROR running autoinstall", 0 == p.exitValue());
        }
        catch (Exception err) {
            err.printStackTrace();
        }
    }


    @Inject
    private AutoUpgradeRunner autoUpgradeRunnerOperator;

    @TestId(id = "VCDB_autoupgrade", title = "Upgrade in cloud environment")
    @Test(groups={"Acceptance"})
    public void autoUpgradeLITP2() {

        String cloud = "cloud";
        assertTrue("ERROR running autoinstall", 0 == (autoUpgradeRunnerOperator.autoUpgradeLITP2(cloud)));
    }

    @TestId(id = "LITP2_autoupgrade_rsyslog7", title = "AutoUpgrade and Restore")
    @Test(groups={"ACCEPTANCE"})
    public void autoUpgradePhysical() throws TimeoutException, FileNotFoundException {

        String rsyslog8 = "False";
        assertTrue("ERROR running autoinstall", 0 == (autoUpgradeRunnerOperator.autoUpgradeLITP2(rsyslog8)));
    }

    @TestId(id = "LITP2_autoupgrade_rsyslog8", title = "AutoUpgrade with rsyslog8")
    @Test(groups={"ACCEPTANCE"}, dependsOnMethods={"autoUpgradePhysical"})
    public void autoUpgradePhysicalRsyslog8() throws TimeoutException, FileNotFoundException {
        
        String rsyslog8 ="True";
        assertTrue("ERROR running autoinstall", 0 == (autoUpgradeRunnerOperator.autoUpgradeLITP2(rsyslog8)));
    }

    /* - FUTURE WORK
    @Inject
    private ExpansionRunner expansionRunnerOperator;
    
    @TestId(id = "Expansion2-4", title = "Expansion TAF testcase that calls Expansion Runner - 2 node to 4")
    @Test(groups={"ACCEPTANCE"})
    public void expansion1() throws TimeoutException, FileNotFoundException {
        
        String option = "expand1";
        assertTrue("ERROR running autoinstall", "0" == (expansionRunnerOperator.expandLITP2(option)));
        // expansionRunnerOperator.expandLITP2();
    }

    @TestId(id = "BackupRestore", title = "Restore used in Expansion")
    @Test(groups={"ACCEPTANCE"})
    public void backupRestore() throws TimeoutException, FileNotFoundException {
        String option = "backupRestore";
        assertTrue("ERROR running autoinstall", "0" == (expansionRunnerOperator.expandLITP2(option)));
    }

    @TestId(id = "Expansion2-4-2Restore", title = "Expansion TAF testcase that calls Expansion Runner - 2 node to 4 to 2 with restore")
    @Test(groups={"ACCEPTANCE"})
    public void expansion2() throws TimeoutException, FileNotFoundException {

        String option = "expand2";
        assertTrue("ERROR running autoinstall", "0" == (expansionRunnerOperator.expandLITP2(option)));
    }

    @TestId(id = "Expansion2-4-2", title = "Expansion TAF testcase that calls Expansion Runner - 2 node to 4 to 2")
    @Test(groups={"ACCEPTANCE"})
    public void expansion3() throws TimeoutException, FileNotFoundException {
        String option = "expand3";
        assertTrue("ERROR running autoinstall", "0" == (expansionRunnerOperator.expandLITP2(option)));
    }
    */


} 
