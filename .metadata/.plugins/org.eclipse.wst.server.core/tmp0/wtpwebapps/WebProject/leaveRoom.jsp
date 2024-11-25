<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, javax.servlet.http.Cookie" %>

<%
    // 방 ID를 요청 파라미터에서 가져오기
    String roomId = request.getParameter("roomId");
    if (roomId == null) {
        response.sendRedirect("main.jsp"); // 방 ID가 없으면 메인 페이지로 이동
        return;
    }

    // 사용자 정보를 쿠키에서 가져오기
    Cookie[] cookies = request.getCookies();
    String userId = null; // 사용자 ID
    if (cookies != null) {
        for (Cookie cookie : cookies) {
            if (cookie.getName().equals("userId")) {
                userId = cookie.getValue();
                break;
            }
        }
    }

    if (userId != null) {
        Connection conn = null;
        PreparedStatement pstmt = null;

        try {
            String url = "jdbc:mariadb://127.0.0.1:3306/userdb?useUnicode=true&characterEncoding=UTF-8";
            String dbUser = "root";
            String dbPassword = "1234";
            conn = DriverManager.getConnection(url, dbUser, dbPassword);

            // 1. 사용자가 참여 중인 방에서 room_id를 null로 업데이트
            String updateRoomSql = "UPDATE users SET room_id = NULL WHERE id = ?";
            pstmt = conn.prepareStatement(updateRoomSql);
            pstmt.setString(1, userId);
            int updatedRows = pstmt.executeUpdate();

            if (updatedRows > 0) {
                out.println("<p>방에서 나갔습니다.</p>");
            } else {
                out.println("<p>방 나가기 실패: 사용자가 방에 참여 중이지 않거나 오류가 발생했습니다.</p>");
            }

            // 2. 방 나가기 후 main.jsp로 리디렉션
            response.sendRedirect("main.jsp");

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
        response.sendRedirect("login.jsp"); // 사용자 ID가 없으면 로그인 페이지로 이동
    }
%>
