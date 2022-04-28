#r "../../../../../hardware_wrapper.dll"
//#r "../../../../../csharp_wrapper.dll"

using GraphScriptCS;
using System;
using System.Threading;

class TestEncoderReaderImpl : EncoderReaderInterface
{
    public override Node FactoryCreate => throw new NotImplementedException();

    public override int GetEncoderPos()
    {
		Logger.Critical("GetEncoderPos!");
        byte[] tByte = new byte[8]{0x07,0x03,0x15,0x07,0x00,0x02,0x71,0xA0};
        byte[] rByte = new byte[8];
        _comm.TryOccupy();
        _comm.Write(tByte);
        Thread.Sleep(400);
        rByte = _comm.Read();
        byte[] posByte = new Byte[4];
        posByte[0] = rByte[4];
        posByte[1] = rByte[3];
        posByte[2] = rByte[6];
        posByte[3] = rByte[5];
        int posVal = BitConverter.ToInt32(posByte,0);
        _comm.ReleaseCtrl();
        return posVal;
    }

    protected override void Link(ILinker linker)
    {
        Logger.Critical("Yes! started Link in script!");
        var tInfo = linker.GetNodeInjection();
        _comm = tInfo.links["reader"][0] as SimpleSynCommInterface;
        var tName = _comm.GetModuleName();
        tName = _comm.GetLinkName(); // return factory_hyb::SimpleSynComm::EncoderReader
        Logger.Critical("Link to " + tName);
    }

    private SimpleSynCommInterface _comm;
}

return new TestEncoderReaderImpl();