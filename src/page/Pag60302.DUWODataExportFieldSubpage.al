page 60302 "DUWO Data Export Field Subpage"
{
    Caption = 'Data Export Fields';
    PageType = ListPart;
    SourceTable = "DUWO Data Export Field Setup";
    AutoSplitKey = true;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Fields)
            {
                field("Field No."; Rec."Field No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'The field number.';
                }
                field("Field Name"; Rec."Field Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'The field name.';
                }
                field("Field Caption"; Rec."Field Caption")
                {
                    ApplicationArea = All;
                    ToolTip = 'The field caption.';
                }
                field("Field Type"; Rec."Field Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'The data type of the field.';
                }
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                    ToolTip = 'Whether this field is included in the export.';
                }
                field("Is FlowField"; Rec."Is FlowField")
                {
                    ApplicationArea = All;
                    ToolTip = 'Indicates whether this field is a FlowField.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(AddAllFields)
            {
                Caption = 'Add All Fields';
                ApplicationArea = All;
                ToolTip = 'Add all fields of the table to the export setup.';
                Image = AddContacts;

                trigger OnAction()
                begin
                    AddAllTableFields();
                end;
            }
            action(EnableSelected)
            {
                Caption = 'Enable Selected';
                ApplicationArea = All;
                ToolTip = 'Enable the selected fields for export.';
                Image = Approve;

                trigger OnAction()
                var
                    FieldSetup: Record "DUWO Data Export Field Setup";
                begin
                    CurrPage.SetSelectionFilter(FieldSetup);
                    FieldSetup.ModifyAll(Enabled, true);
                    CurrPage.Update(false);
                end;
            }
            action(DisableSelected)
            {
                Caption = 'Disable Selected';
                ApplicationArea = All;
                ToolTip = 'Disable the selected fields for export.';
                Image = Reject;

                trigger OnAction()
                var
                    FieldSetup: Record "DUWO Data Export Field Setup";
                begin
                    CurrPage.SetSelectionFilter(FieldSetup);
                    FieldSetup.ModifyAll(Enabled, false);
                    CurrPage.Update(false);
                end;
            }
            action(RemoveAllFields)
            {
                Caption = 'Remove All Fields';
                ApplicationArea = All;
                ToolTip = 'Remove all field lines from the export setup.';
                Image = Delete;

                trigger OnAction()
                var
                    FieldSetup: Record "DUWO Data Export Field Setup";
                begin
                    FieldSetup.CopyFilters(Rec);
                    if FieldSetup.IsEmpty() then
                        exit;
                    if not Confirm('Remove all field lines?') then
                        exit;
                    FieldSetup.DeleteAll(true);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    local procedure AddAllTableFields()
    var
        TableSetup: Record "DUWO Data Export Table Setup";
        AddedCount: Integer;
    begin
        if not TableSetup.Get(Rec."Table No.") then
            Error('Table setup not found.');

        AddedCount := TableSetup.AddAllTableFields();
        Message('%1 field(s) added.', AddedCount);
        CurrPage.Update(false);
    end;
}
