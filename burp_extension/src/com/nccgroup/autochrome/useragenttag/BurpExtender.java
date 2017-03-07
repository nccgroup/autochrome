package com.nccgroup.autochrome.useragenttag;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.StringReader;
import java.nio.charset.Charset;
import java.util.regex.Pattern;

import burp.IBurpExtender;
import burp.IBurpExtenderCallbacks;
import burp.IHttpRequestResponse;
import burp.IInterceptedProxyMessage;
import burp.IProxyListener;

public class BurpExtender implements IBurpExtender {
	IBurpExtenderCallbacks callbacks;
	final Charset charset = Charset.forName("UTF-8");
	final Pattern headerSplitPattern = Pattern.compile(":");
	final Pattern userAgentSplitPattern = Pattern.compile("\\s+");
	final String autochromeProduct = "autochrome/";

	public BurpExtender() {
	}
	
	String getAutochromeProductName(String header) {
		// This is a giant hack. It doesn't fully parse the user-agent,
		// instead just splitting it by strings to find the
		// "autochrome/profilename" inside it somewhere.
		String[] products = userAgentSplitPattern.split(header);

		for (String product : products) {
			if (product.startsWith(autochromeProduct)) {
				return product.substring(autochromeProduct.length());
			}
		}
		
		return null;
	}
	
	String getAutochromeProfile(String req) {
		// Everything about this is terrible. We should probably care if it fails...
		try {
			BufferedReader reader = new BufferedReader(new StringReader(req));

			// Throw away the request line
			reader.readLine();

			// Manually check each header to see if it's the User-Agent
			String line;
			do {
				line = reader.readLine();
				// This will fail on User-Agent headers that have spaces before the colon
				String[] kv = headerSplitPattern.split(line, 2);
				if (kv.length == 2 && "User-Agent".equalsIgnoreCase(kv[0])) {
					// Process the value and extract the relevant thing
					return getAutochromeProductName(kv[1]);
				}
			} while (line != "");
		} catch (IOException e) {
			this.callbacks.printError("Error processing headers: " + e.getMessage());
		}

		return null;
	}

	@Override
	public void registerExtenderCallbacks(IBurpExtenderCallbacks callbacks) {
		this.callbacks = callbacks;
		
		callbacks.registerProxyListener(new IProxyListener() {
			@Override
			public void processProxyMessage(boolean messageIsRequest,
					IInterceptedProxyMessage message) {
				// We only care about requests.
				if (!messageIsRequest) {
					callbacks.printOutput("Ignoring response");
					return;
				}
				
				// Grab the request, which is a string.
				callbacks.printOutput("Handling request");
				IHttpRequestResponse reqresp = message.getMessageInfo();
				String req = new String(reqresp.getRequest(), charset);
				
				// Set the comment if there is a comment to set.
				String comment = getAutochromeProfile(req);
				if (comment != null && comment.length() > 0) {
					reqresp.setComment(comment);
					callbacks.printOutput("Set comment to " + comment);
				}
			}
		});
	}
}
