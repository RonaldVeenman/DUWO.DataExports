table 60300 "DUWO Data Export Table Setup"
{
    Caption = 'Data Export Table Setup';
    LookupPageId = "DUWO Data Export Table List";
    DrillDownPageId = "DUWO Data Export Table List";
    DataClassification = CustomerContent;

    fields
    {
        field(2; "Table No."; Integer)
        {
            Caption = 'Table No.';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));

            trigger OnValidate()
            var
                AllObjWithCaption: Record AllObjWithCaption;
            begin
                if AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Table, "Table No.") then
                    "Table Name" := CopyStr(AllObjWithCaption."Object Name".Replace(' ', '_').Replace('/', '_'), 1, MaxStrLen("Table Name"))
                else
                    "Table Name" := '';
            end;
        }
        field(3; "Table Name"; Text[250])
        {
            Caption = 'Table Name';
            Editable = false;
        }
        field(4; Enabled; Boolean)
        {
            Caption = 'Enabled';
            InitValue = true;
        }
        field(5; Description; Text[250])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(PK; "Table No.")
        {
            Clustered = true;
        }
    }

    trigger OnDelete()
    var
        FieldSetup: Record "DUWO Data Export Field Setup";
    begin
        FieldSetup.SetRange("Table No.", "Table No.");
        FieldSetup.DeleteAll(true);
    end;

    procedure AddAllTableFields(): Integer
    var
        FieldRec: Record Field;
        FieldSetup: Record "DUWO Data Export Field Setup";
        AddedCount: Integer;
    begin
        FieldRec.SetRange(TableNo, "Table No.");
        FieldRec.SetRange(Enabled, true);
        FieldRec.SetFilter(ObsoleteState, '<>%1', FieldRec.ObsoleteState::Removed);
        if FieldRec.FindSet() then
            repeat
                if not FieldSetup.Get("Table No.", FieldRec."No.") then begin
                    FieldSetup.Init();
                    FieldSetup."Table No." := "Table No.";
                    FieldSetup.Validate("Field No.", FieldRec."No.");
                    FieldSetup.Enabled := true;
                    FieldSetup.Insert(true);
                    AddedCount += 1;
                end;
            until FieldRec.Next() = 0;
        exit(AddedCount);
    end;
}
