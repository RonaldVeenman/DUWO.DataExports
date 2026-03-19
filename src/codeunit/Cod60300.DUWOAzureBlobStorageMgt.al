codeunit 60300 "DUWO Azure Blob Storage Mgt."
{
    var
        ABSBlobClient: Codeunit "ABS Blob Client";
        ABSContainerClient: Codeunit "ABS Container Client";
        StorageServiceAuth: Codeunit "Storage Service Authorization";
        IsInitialized: Boolean;
        ExportingTableLbl: Label 'Exporting Table #1## of #2##\Table: #3##########\Progress: @4@@@@@@@@@@', Comment = 'Exporting Table %1 of %2\nTable: %3\nProgress: %4%';

    procedure Initialize(StorageAccountName: Text; SASToken: SecretText; ContainerName: Text)
    var
        Authorization: Interface "Storage Service Authorization";
    begin
        Authorization := StorageServiceAuth.UseReadySAS(SASToken);
        ABSBlobClient.Initialize(StorageAccountName, ContainerName, Authorization);
        ABSContainerClient.Initialize(StorageAccountName, Authorization);
        IsInitialized := true;
    end;

    procedure Initialize(StorageAccountName: Text; SASToken: SecretText; ContainerName: Text; BaseUrl: Text)
    var
        Authorization: Interface "Storage Service Authorization";
    begin
        Authorization := StorageServiceAuth.UseReadySAS(SASToken);
        ABSBlobClient.Initialize(StorageAccountName, ContainerName, Authorization);
        ABSBlobClient.SetBaseUrl(BaseUrl);
        ABSContainerClient.Initialize(StorageAccountName, Authorization);
        ABSContainerClient.SetBaseUrl(BaseUrl);
        IsInitialized := true;
    end;

    procedure UploadBlob(BlobName: Text; var BlobContent: InStream): Boolean
    var
        ABSOperationResponse: Codeunit "ABS Operation Response";
    begin
        CheckInitialized();
        ABSOperationResponse := ABSBlobClient.PutBlobBlockBlobStream(BlobName, BlobContent);
        if not ABSOperationResponse.IsSuccessful() then
            Error(ABSOperationResponse.GetError());
        exit(true);
    end;

    procedure DownloadBlob(BlobName: Text; var BlobContent: InStream): Boolean
    var
        ABSOperationResponse: Codeunit "ABS Operation Response";
    begin
        CheckInitialized();
        ABSOperationResponse := ABSBlobClient.GetBlobAsStream(BlobName, BlobContent);
        if not ABSOperationResponse.IsSuccessful() then
            Error(ABSOperationResponse.GetError());
        exit(true);
    end;

    procedure ListBlobs(var ABSContainerContent: Record "ABS Container Content"): Boolean
    var
        ABSOperationResponse: Codeunit "ABS Operation Response";
    begin
        CheckInitialized();
        ABSOperationResponse := ABSBlobClient.ListBlobs(ABSContainerContent);
        if not ABSOperationResponse.IsSuccessful() then
            Error(ABSOperationResponse.GetError());
        exit(true);
    end;

    procedure DeleteBlob(BlobName: Text): Boolean
    var
        ABSOperationResponse: Codeunit "ABS Operation Response";
    begin
        CheckInitialized();
        ABSOperationResponse := ABSBlobClient.DeleteBlob(BlobName);
        if not ABSOperationResponse.IsSuccessful() then
            Error(ABSOperationResponse.GetError());
        exit(true);
    end;

    procedure TestConnection()
    var
        ABSContainer: Record "ABS Container";
        ABSContainerContent: Record "ABS Container Content";
        ABSOperationResponse: Codeunit "ABS Operation Response";
    begin
        CheckInitialized();

        // Try listing containers to test basic connectivity
        ABSOperationResponse := ABSContainerClient.ListContainers(ABSContainer);
        if ABSOperationResponse.IsSuccessful() then
            Message('Connection successful. Found %1 container(s).', ABSContainer.Count())
        else begin
            // If listing containers fails, try listing blobs directly
            ABSOperationResponse := ABSBlobClient.ListBlobs(ABSContainerContent);
            if ABSOperationResponse.IsSuccessful() then
                Message('Container access successful. Found %1 blob(s).', ABSContainerContent.Count())
            else
                Message('Connection test failed.\Error: %1', ABSOperationResponse.GetError());
        end;
    end;

    procedure CreateAndUploadTestFile()
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
    begin
        CheckInitialized();
        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText('This is a test file created by DUWO Data Exports.');
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        UploadBlob('testRV.txt', InStr);
        Message('File testRV.txt has been uploaded successfully.');
    end;

    procedure ExportTable(TableSetup: Record "DUWO Data Export Table Setup")
    var
        DialogWindow: Dialog;
    begin
        DialogWindow.Open(ExportingTableLbl);
        DialogWindow.Update(1, 1);
        DialogWindow.Update(2, 1);
        ExportTableWithDialog(TableSetup, DialogWindow);
        DialogWindow.Close();
    end;

    local procedure ExportTableWithDialog(TableSetup: Record "DUWO Data Export Table Setup"; var DialogWindow: Dialog)
    var
        FieldSetup: Record "DUWO Data Export Field Setup";
        FieldRec: Record Field;
        TempBlob: Codeunit "Temp Blob";
        RecRef: RecordRef;
        FldRef: FieldRef;
        OutStr: OutStream;
        InStr: InStream;
        Line: TextBuilder;
        BlobName: Text;
        IsFirst: Boolean;
        TotalRecords: Integer;
        RecordCounter: Integer;
    begin
        CheckInitialized();

        if not TableSetup.Enabled then
            Error('Table %1 is not enabled for export.', TableSetup."Table Name");

        FieldSetup.SetRange("Table No.", TableSetup."Table No.");
        FieldSetup.SetRange(Enabled, true);
        if FieldSetup.IsEmpty() then
            Error('No enabled fields configured for table %1.', TableSetup."Table Name");

        // Remove obsolete fields from the setup before exporting
        FieldSetup.FindSet();
        repeat
            if FieldRec.Get(TableSetup."Table No.", FieldSetup."Field No.") then begin
                if FieldRec.ObsoleteState in [FieldRec.ObsoleteState::Removed, FieldRec.ObsoleteState::Pending] then begin
                    FieldSetup.Enabled := false;
                    FieldSetup.Modify();
                end;
            end else begin
                FieldSetup.Enabled := false;
                FieldSetup.Modify();
            end;
        until FieldSetup.Next() = 0;

        // Re-filter to only enabled (non-obsolete) fields
        FieldSetup.SetRange(Enabled, true);
        if FieldSetup.IsEmpty() then
            Error('No valid fields remaining for table %1 after excluding obsolete fields.', TableSetup."Table Name");

        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);

        // Write header line with field captions
        IsFirst := true;
        FieldSetup.FindSet();
        repeat
            if not IsFirst then
                Line.Append(';');
            Line.Append(FormatCsvField(FieldSetup."Field Caption"));
            IsFirst := false;
        until FieldSetup.Next() = 0;
        OutStr.WriteText(Line.ToText());

        // Write data lines
        RecRef.Open(TableSetup."Table No.");
        TotalRecords := RecRef.Count();
        RecordCounter := 0;

        DialogWindow.Update(3, Format(TableSetup."Table No.") + ' - ' + TableSetup."Table Name");
        DialogWindow.Update(4, 0);

        if RecRef.FindSet() then
            repeat
                RecordCounter += 1;
                Line.Clear();
                IsFirst := true;
                FieldSetup.FindSet();
                repeat
                    if not IsFirst then
                        Line.Append(';');
                    FldRef := RecRef.Field(FieldSetup."Field No.");
                    if FieldRec.Get(TableSetup."Table No.", FieldSetup."Field No.") then
                        if FieldRec.Class = FieldRec.Class::FlowField then
                            FldRef.CalcField();
                    Line.Append(FormatCsvField(Format(FldRef.Value)));
                    IsFirst := false;
                until FieldSetup.Next() = 0;
                OutStr.WriteText();
                OutStr.WriteText(Line.ToText());

                if (RecordCounter mod 100) = 0 then
                    DialogWindow.Update(4, Round(RecordCounter / TotalRecords * 10000, 1));
            until RecRef.Next() = 0;
        RecRef.Close();

        // Upload to blob storage
        BlobName := Format(CurrentDateTime, 0, '<Year4><Month,2><Day,2>_<Hours24,2><Minutes,2><Seconds,2>') + '.' + CompanyName + '_' + Format(TableSetup."Table No.") + '_' + TableSetup."Table Name" + '.csv';
        BlobName := BlobName.Replace(' ', '_');

        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        UploadBlob(BlobName, InStr);
        //Message('Table %1 exported as %2.', TableSetup."Table Name", BlobName);
    end;

    procedure ExportAllTables()
    var
        TableSetup: Record "DUWO Data Export Table Setup";
        DialogWindow: Dialog;
        TableCounter: Integer;
        TotalTables: Integer;
    begin
        CheckInitialized();
        TableSetup.SetRange(Enabled, true);
        if TableSetup.IsEmpty() then
            Error('No enabled tables configured for export.');

        TotalTables := TableSetup.Count();
        TableCounter := 0;

        DialogWindow.Open(ExportingTableLbl);
        DialogWindow.Update(2, TotalTables);

        TableSetup.FindSet();
        repeat
            TableCounter += 1;
            DialogWindow.Update(1, TableCounter);
            ExportTableWithDialog(TableSetup, DialogWindow);
        until TableSetup.Next() = 0;

        DialogWindow.Close();
    end;

    local procedure FormatCsvField(Value: Text): Text
    begin
        if (Value.Contains('"')) or (Value.Contains(';')) or (Value.Contains('\n')) then begin
            Value := Value.Replace('"', '""');
            exit('"' + Value + '"');
        end;
        exit(Value);
    end;

    local procedure CheckInitialized()
    begin
        if not IsInitialized then
            Error('Azure Blob Storage client is not initialized. Call Initialize first.');
    end;
}
