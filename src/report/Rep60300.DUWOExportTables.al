report 60300 "DUWO Export Tables"
{
    Caption = 'DUWO Export Tables';
    UsageCategory = Administration;
    ApplicationArea = All;
    ProcessingOnly = true;

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(AzureBlobStorage)
                {
                    Caption = 'Azure Blob Storage';

                    field("Storage Account Name"; StorageAccountName)
                    {
                        Caption = 'Storage Account Name';
                        ApplicationArea = All;
                        ToolTip = 'The Azure Storage account name (e.g. mystorageaccount).';
                    }
                    field("Base URL"; BaseUrl)
                    {
                        Caption = 'Base URL';
                        ApplicationArea = All;
                        ToolTip = 'The base URL pattern. Use %1 as placeholder for the storage account name. Leave empty for default (https://%1.blob.core.windows.net).';
                    }
                    field("SAS Token"; SASToken)
                    {
                        Caption = 'SAS Token';
                        ApplicationArea = All;
                        ToolTip = 'The Shared Access Signature token for authentication.';
                        ExtendedDatatype = Masked;
                    }
                    field("Container Name"; ContainerName)
                    {
                        Caption = 'Container Name';
                        ApplicationArea = All;
                        ToolTip = 'The name of the Azure Blob Storage container.';
                    }
                }
            }
        }
    }

    trigger OnInitReport()
    begin
        StorageAccountName := 'stzigsftpprod';
        BaseUrl := 'https://%1.blob.core.windows.net';  // Change to https://%1.dfs.core.windows.net if using Data Lake Storage
        ContainerName := 'hbvg';
        SASToken := 'se=2027-03-18T23:00:00Z&si=hbvg_policy&spr=https&sv=2024-11-04&sr=c&sig=DaIUPyFQUfekJZaOdpx4Dige3EgU6ymOsT8iqNTQvJY%3D';
    end;

    trigger OnPreReport()
    var
        AzureBlobMgt: Codeunit "DUWO Azure Blob Storage Mgt.";
    begin
        if StorageAccountName = '' then
            Error('Storage Account Name is required.');
        if SASToken = '' then
            Error('SAS Token is required.');
        if ContainerName = '' then
            Error('Container Name is required.');

        if BaseUrl <> '' then
            AzureBlobMgt.Initialize(StorageAccountName, SASToken, ContainerName, BaseUrl)
        else
            AzureBlobMgt.Initialize(StorageAccountName, SASToken, ContainerName);
        AzureBlobMgt.ExportAllTables();
    end;

    var
        StorageAccountName: Text[250];
        BaseUrl: Text;
        SASToken: Text[2048];
        ContainerName: Text[250];
}
