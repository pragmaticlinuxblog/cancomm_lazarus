A record for grouping all CAN message related data.

```pascal
type TCanMsg = packed record
  Id: LongWord;
  Ext: Boolean;
  Len: Byte;
  Data: array [0..(CANMSG_FD_MAX_DATA_LEN-1)] of Byte;
  Flags : bitpacked record
    Fd: Boolean;
    Err: Boolean;
  end;
  Timestamp: QWord;
end;
```

## Fields

| Name        | Description                                                  |
| ----------- | ------------------------------------------------------------ |
| `Id`        | CAN message identifier. `0..$7FF` for 11-bit CAN identifiers, `0..$1FFFFFFF` for 29-bit CAN identifiers. |
| `Ext`       | `True` for a 29-bit CAN identifier, `False` for an 11-bit CAN identifier. |
| `Len`       | Number of data bytes inside the CAN message. `0..8` for CAN classic messages. `0..8`, `12`, `16`, `20`, `24`, `32`, `48` or `64` for CAN FD messages. |
| `Data`      | Array with message data bytes.                               |
| `Flags`     | Message related flags: <br>&nbsp;&nbsp;`Fd` - `True` for a CAN FD message, `False` for a CAN classic message.<br> &nbsp;&nbsp;`Err` - `True` if the message is an error frame, `False` for a data frame (only used internally). |
| `Timestamp` | Timestamp in microseconds of when the CAN message was transmitted or received. |

```pascal linenums="1" title="Example - Declaring and initializing a TCanMsg variable:"
procedure TForm1.BtnTransmitClick(Sender: TObject);
var
  TxMsg: TCanMsg;
begin
  TxMsg.Id := $123;         // Set the CAN message identifier
  TxMsg.Ext := False;       // Set the identifier type to 11-bit
  TxMsg.Flags.Fd := False;  // Configure the message as CAN classic
  TxMsg.Flags.Err := False; // CAN data frame
  TxMsg.Len := 2;           // Set the data length to 2 bytes
  TxMsg.Data[0] := $37;     // Set the value of data byte 0
  TxMsg.Data[1] := $A5;     // Set the value of data byte 1

  // Transmit the CAN message.
  CanSocket1.Transmit(TxMsg);
end;
```

