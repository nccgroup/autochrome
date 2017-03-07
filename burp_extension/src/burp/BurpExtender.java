package burp;

public class BurpExtender implements IBurpExtender {
	@Override
	public void registerExtenderCallbacks(IBurpExtenderCallbacks callbacks) {
		com.nccgroup.autochrome.useragenttag.BurpExtender shim = new com.nccgroup.autochrome.useragenttag.BurpExtender();
		shim.registerExtenderCallbacks(callbacks);
	}
}
