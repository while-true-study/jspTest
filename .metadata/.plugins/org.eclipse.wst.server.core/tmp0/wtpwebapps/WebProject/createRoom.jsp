<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, javax.servlet.http.Cookie" %>

<%
	request.setCharacterEncoding("UTF-8");
    // 쿠키에서 사용자 이름과 userId 가져오기
    Cookie[] cookies = request.getCookies();
    String userId = null;

    if (cookies != null) {
        for (Cookie cookie : cookies) {
            if (cookie.getName().equals("userId")) {
                userId = cookie.getValue();  // 로그인한 사용자 ID 가져오기
            }
        }
    }

    if (userId != null) {  // 로그인된 상태에서만 방 만들기
        String roomName = request.getParameter("roomName");

        if (roomName != null && !roomName.isEmpty()) {
            Connection conn = null;
            PreparedStatement pstmt = null;
            ResultSet rs = null;
            try {
                // 데이터베이스 연결 정보
                String url = "jdbc:mariadb://127.0.0.1:3306/userdb?useUnicode=true&characterEncoding=UTF-8";
                String dbUser = "root";
                String dbPassword = "1234";
                conn = DriverManager.getConnection(url, dbUser, dbPassword);

                // 방을 데이터베이스에 삽입
                String sql = "INSERT INTO rooms (room_name, user_id) VALUES (?, ?)";
                pstmt = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);
                pstmt.setString(1, roomName);
                pstmt.setString(2, userId);  // 로그인된 사용자 ID 저장

                int result = pstmt.executeUpdate();
                if (result > 0) {
                    // 방 생성 후 방 ID 가져오기
                    rs = pstmt.getGeneratedKeys();
                    int roomId = -1;
                    if (rs.next()) {
                        roomId = rs.getInt(1);
                    }

                    // 방 생성 성공 후 해당 방 페이지로 리다이렉트
                    response.sendRedirect("roomPage.jsp?roomId=" + roomId);
                } else {
                    out.println("<p>방 생성 실패!</p>");
                }

            } catch (Exception e) {
                e.printStackTrace();
                out.println("<p>오류 발생: " + e.getMessage() + "</p>");
            } finally {
                try {
                    if (pstmt != null) pstmt.close();
                    if (conn != null) conn.close();
                } catch (SQLException e) {
                    e.printStackTrace();
                }
            }
        } else {
            out.println("<p>방 이름을 입력해주세요.</p>");
        }
    } else {
        out.println("<p>로그인되지 않았습니다. 로그인 후 방을 생성해주세요.</p>");
    }
%>
