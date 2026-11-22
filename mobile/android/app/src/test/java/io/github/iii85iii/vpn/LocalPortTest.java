package io.github.iii85iii.vpn;

import java.net.InetAddress;
import java.net.ServerSocket;
import org.junit.Test;
import static org.junit.Assert.*;

public class LocalPortTest {
    @Test public void occupiedDashboardAndProxyGetDistinctListeners() throws Exception {
        InetAddress local = InetAddress.getByName("127.0.0.1");
        try (ServerSocket old = new ServerSocket(0, 1, local);
             ServerSocket dashboard = CoreRuntime.reservePort(local, old.getLocalPort());
             ServerSocket proxy = CoreRuntime.reservePort(InetAddress.getByName("0.0.0.0"), dashboard.getLocalPort())) {
            assertNotEquals(old.getLocalPort(), dashboard.getLocalPort());
            assertNotEquals(dashboard.getLocalPort(), proxy.getLocalPort());
            assertNotEquals(old.getLocalPort(), proxy.getLocalPort());
        }
    }
}
