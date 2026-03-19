page 60300 "DUWO Data Export Table List"
{
    Caption = 'Data Export Table Setup';
    PageType = List;
    UsageCategory = Administration;
    ApplicationArea = All;
    SourceTable = "DUWO Data Export Table Setup";
    CardPageId = "DUWO Data Export Table Card";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Tables)
            {
                field("Table No."; Rec."Table No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'The table number.';
                }
                field("Table Name"; Rec."Table Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'The name of the table.';
                }
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                    ToolTip = 'Whether this table is included in the export.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'A description for this export table setup.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ExportAllTables)
            {
                Caption = 'Export All Tables';
                ApplicationArea = All;
                ToolTip = 'Export all enabled tables as CSV files to Azure Blob Storage.';
                Image = Export;

                trigger OnAction()
                begin
                    Report.Run(Report::"DUWO Export Tables");
                end;
            }
            action(AddHBVGTables)
            {
                Caption = 'Add HBVG Tables';
                ApplicationArea = All;
                ToolTip = 'Add all tables containing "HBVG" in the name that have data, including all their fields.';
                Image = AddContacts;

                trigger OnAction()
                var
                    AllObj: Record AllObjWithCaption;
                    TableSetup: Record "DUWO Data Export Table Setup";
                    RecRef: RecordRef;
                    TablesAdded: Integer;
                begin
                    AllObj.SetRange("Object Type", AllObj."Object Type"::Table);
                    AllObj.SetFilter("Object Name", '@*HBVG*');
                    if AllObj.IsEmpty() then
                        Error('No tables found with "HBVG" in the name.');

                    TablesAdded := 0;
                    AllObj.FindSet();
                    repeat
                        if not TableSetup.Get(AllObj."Object ID") then begin
                            RecRef.Open(AllObj."Object ID");
                            if not RecRef.IsEmpty() then begin
                                TableSetup.Init();
                                TableSetup.Validate("Table No.", AllObj."Object ID");
                                //TableSetup."Table Name" := CopyStr(AllObj."Object Caption", 1, MaxStrLen(TableSetup."Table Name"));
                                TableSetup.Enabled := true;
                                TableSetup.Insert(true);

                                TableSetup.AddAllTableFields();
                                TablesAdded += 1;
                            end;
                            RecRef.Close();
                        end;
                    until AllObj.Next() = 0;

                    if TablesAdded = 0 then
                        Message('No new HBVG tables with data found to add.')
                    else
                        Message('%1 HBVG table(s) with all fields added.', TablesAdded);

                    CurrPage.Update(false);
                end;
            }
            action(DeleteSelected)
            {
                Caption = 'Delete Selected';
                ApplicationArea = All;
                ToolTip = 'Delete all selected table setup records and their fields.';
                Image = Delete;

                trigger OnAction()
                var
                    TableSetup: Record "DUWO Data Export Table Setup";
                begin
                    CurrPage.SetSelectionFilter(TableSetup);
                    if TableSetup.IsEmpty() then
                        Error('No records selected.');
                    if not Confirm('Delete %1 selected table(s)?', false, TableSetup.Count()) then
                        exit;
                    TableSetup.DeleteAll(true);
                    CurrPage.Update(false);
                end;
            }
            action(EnableSelected)
            {
                Caption = 'Enable Selected';
                ApplicationArea = All;
                ToolTip = 'Enable all selected tables for export.';
                Image = Approve;

                trigger OnAction()
                var
                    TableSetup: Record "DUWO Data Export Table Setup";
                begin
                    CurrPage.SetSelectionFilter(TableSetup);
                    if TableSetup.IsEmpty() then
                        Error('No records selected.');
                    TableSetup.ModifyAll(Enabled, true);
                    CurrPage.Update(false);
                end;
            }
            action(DisableSelected)
            {
                Caption = 'Disable Selected';
                ApplicationArea = All;
                ToolTip = 'Disable all selected tables for export.';
                Image = Reject;

                trigger OnAction()
                var
                    TableSetup: Record "DUWO Data Export Table Setup";
                begin
                    CurrPage.SetSelectionFilter(TableSetup);
                    if TableSetup.IsEmpty() then
                        Error('No records selected.');
                    TableSetup.ModifyAll(Enabled, false);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            actionref(ExportAllTablesRef; ExportAllTables) { }
            actionref(AddHBVGTablesRef; AddHBVGTables) { }
            actionref(DeleteSelectedRef; DeleteSelected) { }
            actionref(EnableSelectedRef; EnableSelected) { }
            actionref(DisableSelectedRef; DisableSelected) { }
        }
    }
}
