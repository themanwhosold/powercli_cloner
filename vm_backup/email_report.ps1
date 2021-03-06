add-pssnapin VMware.VimAutomation.Core

Function WriteVMStatusToFile
{
    param ([string]$myhost, [string]$file_path)
    
    $VMs = Get-VMHost $myhost | Get-VM
    
    if($VMs){
        foreach($vm in $VMs) {
            Out-File -FilePath $file_path -InputObject $vm.name -Append
            Out-File -FilePath $file_path -InputObject $vm.powerstate -Append
            Out-File -FilePath $file_path -InputObject "--------------------" -Append
            Out-File -FilePath $file_path -InputObject "" -Append
        }
    } 
    else {
        Out-File -FilePath $file_path -InputObject "Server not available." -Append
    }
    
}

#Set VCenter servername
$vcenter_server = "vcenter"

#Report path
$report_path = "C:\scripts\vm_backup\report.txt"

#Connect to vCenter
Connect-VIServer $vcenter_server

$LastDays = 1

    $EventFilterSpecByTime = New-Object VMware.Vim.EventFilterSpecByTime
    If ($LastDays)
    {
        $EventFilterSpecByTime.BeginTime = (get-date).AddDays(-$($LastDays))
    }
    $EventFilterSpec = New-Object VMware.Vim.EventFilterSpec
    $EventFilterSpec.Time = $EventFilterSpecByTime
    $EventFilterSpec.DisableFullMessage = $False
    $EventFilterSpec.Type = "VmCloneFailedEvent"
    $EventManager = Get-View EventManager
    $NewCloneTasks = $EventManager.QueryEvents($EventFilterSpec)

    Out-File -FilePath $report_path -InputObject "CLONE FAILURES:"
    Out-File -FilePath $report_path -InputObject "==================" -Append
 
 if($NewCloneTasks) {
    Foreach ($Task in $NewCloneTasks)
    {
        
        $item = "Destination host: " + $Task.destHost.name
        Out-File -FilePath $report_path -InputObject $item -Append
        $item = "VM Name: " + $Task.destName
        Out-File -FilePath $report_path -InputObject $item -Append
        $item = "Errors: " + $Task.reason.localizedMessage
        Out-File -FilePath $report_path -InputObject $item -Append
        Out-File -FilePath $report_path -InputObject "" -Append
    }
 } else {
   Out-File -FilePath $report_path -InputObject "There were no clone failures in the last 24 hours." -Append
 }
    Out-File -FilePath $report_path -InputObject "" -Append
    Out-File -FilePath $report_path -InputObject "" -Append
    Out-File -FilePath $report_path -InputObject "VMs on 2950:" -Append
    Out-File -FilePath $report_path -InputObject "=====================" -Append
    WriteVMStatusToFile "192.168.1.240" $report_path
   
    Out-File -FilePath $report_path -InputObject "" -Append
    Out-File -FilePath $report_path -InputObject "" -Append
    Out-File -FilePath $report_path -InputObject "VMs on T610:" -Append
    Out-File -FilePath $report_path -InputObject "=====================" -Append
    WriteVMStatusToFile "192.168.1.244" $report_path
    
    Out-File -FilePath $report_path -InputObject "" -Append
    Out-File -FilePath $report_path -InputObject "" -Append
    Out-File -FilePath $report_path -InputObject "VMs on Offsite:" -Append
    Out-File -FilePath $report_path -InputObject "=====================" -Append
    WriteVMStatusToFile "192.168.1.239" $report_path
    
    
    
#* =========================
#* SMTP Mail Alert
#* =========================

#* Create new .NET object and assign to variable
$mail = New-Object System.Net.Mail.MailMessage

#* Sender Address
$mail.From = "vsphere@coogle.alexcooper.com";

#* Recipient Address
$mail.To.Add("alexcooper@endpoint.com");
$mail.To.Add("matt@alexcooper.com");

#* Message Subject
$mail.Subject = "Alex Cooper VM Backup Report";

#* Message Body
$mail.Body = (Get-Content $report_path | out-string)

#* Connect to your mail server
$smtp = New-Object System.Net.Mail.SmtpClient("192.168.1.252");

#* Send Email
$smtp.Send($mail);