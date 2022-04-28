using System;
using System.IO;
using System.Runtime.Serialization.Formatters.Binary;

namespace McBaseInfo
{
    [Serializable]
    public class BaseClone<T>
    {
        public virtual T Clone()
        {
            MemoryStream memoryStream = new MemoryStream();
            BinaryFormatter formatter = new BinaryFormatter();
            formatter.Serialize(memoryStream, this);
            memoryStream.Position = 0;
            return (T)formatter.Deserialize(memoryStream);
        }
    }
}